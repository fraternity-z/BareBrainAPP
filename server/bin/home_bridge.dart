import 'dart:async';
import 'dart:io';

import 'relay_protocol.dart';
import 'server_environment.dart';

Future<void> main() async {
  final environment = await ServerEnvironment.load();
  final config = BridgeConfig.fromEnvironment(environment);
  final bridge = HomeBridge(config);
  await bridge.run();
}

class BridgeConfig {
  const BridgeConfig({
    required this.relayUrl,
    required this.deviceId,
    required this.deviceToken,
    required this.bareBrainUrl,
    required this.reconnectDelay,
    required this.responseTimeout,
  });

  factory BridgeConfig.fromEnvironment(ServerEnvironment environment) {
    return BridgeConfig(
      relayUrl: Uri.parse(
        environment.string(
          'BRIDGE_RELAY_URL',
          'ws://127.0.0.1:8080/ws/device',
        ),
      ),
      deviceId: environment.string('BRIDGE_DEVICE_ID', 'home'),
      deviceToken: environment.string(
        'BRIDGE_DEVICE_TOKEN',
        'change-device-token',
      ),
      bareBrainUrl: Uri.parse(
        environment.string(
          'BRIDGE_BAREBRAIN_URL',
          'ws://192.168.1.100:18789/',
        ),
      ),
      reconnectDelay: Duration(
        milliseconds: environment.integer('BRIDGE_RECONNECT_MS', 3000),
      ),
      responseTimeout: Duration(
        milliseconds: environment.integer('BRIDGE_TIMEOUT_MS', 90000),
      ),
    );
  }

  final Uri relayUrl;
  final String deviceId;
  final String deviceToken;
  final Uri bareBrainUrl;
  final Duration reconnectDelay;
  final Duration responseTimeout;

  Uri get authenticatedRelayUrl {
    return relayUrl.replace(
      queryParameters: <String, String>{
        ...relayUrl.queryParameters,
        'device_id': deviceId,
        'token': deviceToken,
      },
    );
  }
}

class HomeBridge {
  const HomeBridge(this._config);

  final BridgeConfig _config;

  Future<void> run() async {
    while (true) {
      try {
        await _connectRelayOnce();
      } on Object catch (error) {
        logWarning('Bridge disconnected: $error');
      }

      await Future<void>.delayed(_config.reconnectDelay);
    }
  }

  Future<void> _connectRelayOnce() async {
    final relay = await WebSocket.connect(
      _config.authenticatedRelayUrl.toString(),
    );
    logInfo('Connected to relay: ${_config.authenticatedRelayUrl.removeQuery()}');

    await for (final data in relay) {
      unawaited(_handleRelayMessage(relay, data));
    }
  }

  Future<void> _handleRelayMessage(WebSocket relay, Object? data) async {
    String requestId = DateTime.now().microsecondsSinceEpoch.toString();
    String? chatId;

    try {
      final request = decodeObject(data);
      final type = requiredString(request, 'type');
      if (type != 'request') {
        throw const RelayProtocolException('Relay payload type must be request');
      }

      requestId = requiredString(request, 'request_id');
      chatId = requiredString(request, 'chat_id');
      final content = requiredString(request, 'content');
      final response = await _sendToBareBrain(
        chatId: chatId,
        content: content,
      );

      relay.add(encodeObject(<String, Object?>{
        'type': 'response',
        'request_id': requestId,
        'chat_id': chatId,
        'content': response,
      }));
    } on Object catch (error) {
      relay.add(encodeObject(errorPayload(
        requestId: requestId,
        chatId: chatId,
        message: error.toString(),
      )));
    }
  }

  Future<String> _sendToBareBrain({
    required String chatId,
    required String content,
  }) async {
    final socket = await WebSocket.connect(_config.bareBrainUrl.toString())
        .timeout(_config.responseTimeout);

    try {
      final responseFuture = socket
          .where((event) => event is String)
          .cast<String>()
          .map(decodeObject)
          .where((payload) {
            return payload['type'] == 'response' &&
                payload['chat_id'] == chatId;
          })
          .first
          .timeout(_config.responseTimeout);

      socket.add(encodeObject(<String, Object?>{
        'type': 'message',
        'chat_id': chatId,
        'content': content,
      }));

      final response = await responseFuture;
      return requiredString(response, 'content');
    } finally {
      await socket.close(WebSocketStatus.normalClosure, 'Request complete');
    }
  }
}

void logInfo(String message) {
  stdout.writeln('[bridge] $message');
}

void logWarning(String message) {
  stderr.writeln('[bridge] $message');
}

extension on Uri {
  String removeQuery() {
    return replace(queryParameters: const <String, String>{}).toString();
  }
}
