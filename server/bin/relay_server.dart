import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'push_notifier.dart';
import 'relay_protocol.dart';
import 'server_environment.dart';

Future<void> main() async {
  final environment = await ServerEnvironment.load();
  final config = RelayConfig.fromEnvironment(environment);
  final server = await HttpServer.bind(config.host, config.port);
  final hub = RelayHub(
    config,
    pushNotifier: PushNotifier(
      config: PushConfig.fromEnvironment(environment),
    ),
  );

  logInfo('BareBrain Relay listening on ${config.host}:${config.port}');
  logInfo('Device endpoint: /ws/device?device_id=${config.deviceId}&token=...');
  logInfo('App endpoint: /ws/app?device_id=${config.deviceId}&token=...');

  await for (final request in server) {
    unawaited(hub.handle(request));
  }
}

class RelayConfig {
  const RelayConfig({
    required this.host,
    required this.port,
    required this.deviceId,
    required this.deviceToken,
    required this.appToken,
  });

  factory RelayConfig.fromEnvironment(ServerEnvironment environment) {
    return RelayConfig(
      host: environment.string('RELAY_HOST', '0.0.0.0'),
      port: environment.integer('RELAY_PORT', 8080),
      deviceId: environment.string('RELAY_DEVICE_ID', 'home'),
      deviceToken: environment.string(
        'RELAY_DEVICE_TOKEN',
        'change-device-token',
      ),
      appToken: environment.string('RELAY_APP_TOKEN', 'change-app-token'),
    );
  }

  final String host;
  final int port;
  final String deviceId;
  final String deviceToken;
  final String appToken;
}

class RelayHub {
  RelayHub(
    this._config, {
    PushNotifier? pushNotifier,
  }) : _pushNotifier = pushNotifier;

  final RelayConfig _config;
  final PushNotifier? _pushNotifier;
  DeviceConnection? _device;
  final List<AppConnection> _apps = <AppConnection>[];
  final Map<String, AppConnection> _pendingApps = <String, AppConnection>{};

  Future<void> handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
      return;
    }

    if (path == '/debug/incoming') {
      await _handleDebugIncoming(request);
      return;
    }

    if (path != '/ws/device' && path != '/ws/app') {
      await _reject(request, HttpStatus.notFound, 'Not found');
      return;
    }

    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      await _reject(request, HttpStatus.badRequest, 'Expected WebSocket');
      return;
    }

    if (path == '/ws/device') {
      await _handleDevice(request);
      return;
    }

    await _handleApp(request);
  }

  Future<void> _handleDebugIncoming(HttpRequest request) async {
    if (request.method != 'POST') {
      await _reject(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    if (!_queryMatches(request, _config.deviceToken)) {
      await _reject(request, HttpStatus.unauthorized, 'Unauthorized debug');
      return;
    }

    try {
      final source = await utf8.decoder.bind(request).join();
      final payload = decodeObject(source);
      _broadcastIncoming(<String, Object?>{
        'type': 'incoming',
        'chat_id': requiredString(payload, 'chat_id'),
        'content': requiredString(payload, 'content'),
      });

      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
    } on Object catch (error) {
      await _reject(request, HttpStatus.badRequest, error.toString());
    }
  }

  Future<void> _handleDevice(HttpRequest request) async {
    if (!_queryMatches(request, _config.deviceToken)) {
      await _reject(request, HttpStatus.unauthorized, 'Unauthorized device');
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    final connection = DeviceConnection(
      socket: socket,
      onMessage: _handleDeviceMessage,
      onDone: () {
        if (_device?.socket == socket) {
          _device = null;
        }
      },
    );

    await _device?.close();
    _device = connection;
    connection.listen();
    logInfo('Device connected: ${_config.deviceId}');
  }

  Future<void> _handleApp(HttpRequest request) async {
    if (!_queryMatches(request, _config.appToken)) {
      await _reject(request, HttpStatus.unauthorized, 'Unauthorized app');
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    final connection = AppConnection(
      socket: socket,
      onMessage: _handleAppMessage,
      onDone: () {
        _apps.removeWhere((app) => app.socket == socket);
        _pendingApps.removeWhere((_, app) => app.socket == socket);
      },
    );

    _apps.add(connection);
    connection.listen();
    logInfo('App connected for device: ${_config.deviceId}');
  }

  bool _queryMatches(HttpRequest request, String expectedToken) {
    final query = request.uri.queryParameters;
    return query['device_id'] == _config.deviceId &&
        query['token'] == expectedToken;
  }

  void _handleAppMessage(AppConnection app, Object? data) {
    String requestId = DateTime.now().microsecondsSinceEpoch.toString();
    String? chatId;

    try {
      final payload = decodeObject(data);
      final type = requiredString(payload, 'type');
      if (type != 'message') {
        throw const RelayProtocolException('App payload type must be message');
      }

      requestId = optionalRequestId(payload);
      chatId = requiredString(payload, 'chat_id');
      final content = requiredString(payload, 'content');
      final device = _device;

      logInfo('App request: chat_id=$chatId, request_id=$requestId');

      if (device == null) {
        app.send(errorPayload(
          requestId: requestId,
          chatId: chatId,
          message: 'Device is offline',
        ));
        return;
      }

      _pendingApps[requestId] = app;
      device.send(<String, Object?>{
        'type': 'request',
        'request_id': requestId,
        'chat_id': chatId,
        'content': content,
      });
    } on Object catch (error) {
      app.send(errorPayload(
        requestId: requestId,
        chatId: chatId,
        message: error.toString(),
      ));
    }
  }

  void _handleDeviceMessage(DeviceConnection device, Object? data) {
    try {
      final payload = decodeObject(data);
      final type = requiredString(payload, 'type');
      if (_isDeviceIncomingPayload(payload, type)) {
        _broadcastIncoming(payload);
        return;
      }

      final requestId = requiredString(payload, 'request_id');
      final app = _pendingApps.remove(requestId);
      if (app == null) {
        logWarning('No app waiting for request_id=$requestId');
        return;
      }

      if (type == 'response') {
        app.send(<String, Object?>{
          'type': 'response',
          'request_id': requestId,
          'chat_id': requiredString(payload, 'chat_id'),
          'content': requiredString(payload, 'content'),
        });
        return;
      }

      if (type == 'error') {
        app.send(<String, Object?>{
          'type': 'error',
          'request_id': requestId,
          'message': requiredString(payload, 'message'),
        });
      }
    } on Object catch (error) {
      logWarning('Invalid device payload: $error');
    }
  }

  bool _isDeviceIncomingPayload(Map<String, Object?> payload, String type) {
    if (type == 'incoming' || type == 'message' || type == 'event') {
      return true;
    }

    return type == 'response' && !_hasRequestId(payload);
  }

  bool _hasRequestId(Map<String, Object?> payload) {
    final requestId = payload['request_id'];
    return requestId is String && requestId.trim().isNotEmpty;
  }

  void _broadcastIncoming(Map<String, Object?> payload) {
    final chatId = requiredString(payload, 'chat_id');
    final content = requiredString(payload, 'content');

    logInfo('Incoming device message: chat_id=$chatId, apps=${_apps.length}');

    for (final app in List<AppConnection>.of(_apps)) {
      app.send(<String, Object?>{
        'type': 'response',
        'chat_id': chatId,
        'content': content,
      });
    }

    unawaited(_sendPushNotification(chatId: chatId, content: content));
  }

  Future<void> _sendPushNotification({
    required String chatId,
    required String content,
  }) async {
    try {
      await _pushNotifier?.notifyIncoming(
        deviceId: _config.deviceId,
        chatId: chatId,
        content: content,
      );
    } on Object catch (error) {
      logWarning('Push notification failed: $error');
    }
  }

  Future<void> _reject(
    HttpRequest request,
    int statusCode,
    String message,
  ) async {
    request.response
      ..statusCode = statusCode
      ..write(message);
    await request.response.close();
  }
}

class DeviceConnection {
  DeviceConnection({
    required this.socket,
    required this.onMessage,
    required this.onDone,
  });

  final WebSocket socket;
  final void Function(DeviceConnection connection, Object? data) onMessage;
  final void Function() onDone;

  void listen() {
    socket.listen(
      (data) => onMessage(this, data),
      onError: (Object error) => logWarning('Device socket error: $error'),
      onDone: onDone,
      cancelOnError: true,
    );
  }

  void send(Map<String, Object?> payload) {
    socket.add(encodeObject(payload));
  }

  Future<void> close() {
    return socket.close(
      WebSocketStatus.goingAway,
      'Replaced by a new device connection',
    );
  }
}

class AppConnection {
  AppConnection({
    required this.socket,
    required this.onMessage,
    required this.onDone,
  });

  final WebSocket socket;
  final void Function(AppConnection connection, Object? data) onMessage;
  final void Function() onDone;

  void listen() {
    socket.listen(
      (data) => onMessage(this, data),
      onError: (Object error) => logWarning('App socket error: $error'),
      onDone: onDone,
      cancelOnError: true,
    );
  }

  void send(Map<String, Object?> payload) {
    socket.add(encodeObject(payload));
  }
}

void logInfo(String message) {
  stdout.writeln('[relay] $message');
}

void logWarning(String message) {
  stderr.writeln('[relay] $message');
}
