import 'dart:async';
import 'dart:io';

import 'relay_protocol.dart';
import 'server_environment.dart';

Future<void> main() async {
  final environment = await ServerEnvironment.load();
  final config = RelayConfig.fromEnvironment(environment);
  final server = await HttpServer.bind(config.host, config.port);
  final hub = RelayHub(config);

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
  RelayHub(this._config);

  final RelayConfig _config;
  DeviceConnection? _device;
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
        _pendingApps.removeWhere((_, app) => app.socket == socket);
      },
    );

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
      final requestId = requiredString(payload, 'request_id');
      final app = _pendingApps.remove(requestId);
      if (app == null) {
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
