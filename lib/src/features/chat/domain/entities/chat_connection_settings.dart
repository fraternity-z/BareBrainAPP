import 'chat_ota_settings.dart';

enum ChatConnectionMode {
  direct,
  relay;

  String get label {
    return switch (this) {
      ChatConnectionMode.direct => '局域网直连',
      ChatConnectionMode.relay => '云端 Relay',
    };
  }
}

class ChatConnectionSettings {
  const ChatConnectionSettings({
    required this.host,
    required this.port,
    required this.clientId,
    required this.responseTimeout,
    this.secure = false,
    this.mode = ChatConnectionMode.direct,
    this.relayDeviceId = '',
    this.relayToken = '',
    this.relayPath = '/ws/app',
    this.otaSettings = const ChatOtaSettings(),
  });

  final String host;
  final int port;
  final String clientId;
  final Duration responseTimeout;
  final bool secure;
  final ChatConnectionMode mode;
  final String relayDeviceId;
  final String relayToken;
  final String relayPath;
  final ChatOtaSettings otaSettings;

  bool get isRelay => mode == ChatConnectionMode.relay;

  Uri get websocketUri {
    if (isRelay) {
      return Uri(
        scheme: secure ? 'wss' : 'ws',
        host: host,
        port: port,
        path: relayPath,
        queryParameters: <String, String>{
          'device_id': relayDeviceId,
          'token': relayToken,
        },
      );
    }

    return Uri(
      scheme: secure ? 'wss' : 'ws',
      host: host,
      port: port,
      path: '/',
    );
  }

  Uri get redactedWebsocketUri {
    if (!isRelay) {
      return websocketUri;
    }

    return Uri(
      scheme: secure ? 'wss' : 'ws',
      host: host,
      port: port,
      path: relayPath,
      queryParameters: <String, String>{
        'device_id': relayDeviceId,
        'token': relayToken.isEmpty ? '' : '***',
      },
    );
  }

  String get connectionLabel {
    return isRelay
        ? '${mode.label} · ${redactedWebsocketUri.toString()}'
        : redactedWebsocketUri.toString();
  }

  ChatConnectionSettings copyWith({
    String? host,
    int? port,
    String? clientId,
    Duration? responseTimeout,
    bool? secure,
    ChatConnectionMode? mode,
    String? relayDeviceId,
    String? relayToken,
    String? relayPath,
    ChatOtaSettings? otaSettings,
  }) {
    return ChatConnectionSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      responseTimeout: responseTimeout ?? this.responseTimeout,
      secure: secure ?? this.secure,
      mode: mode ?? this.mode,
      relayDeviceId: relayDeviceId ?? this.relayDeviceId,
      relayToken: relayToken ?? this.relayToken,
      relayPath: relayPath ?? this.relayPath,
      otaSettings: otaSettings ?? this.otaSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatConnectionSettings &&
            other.host == host &&
            other.port == port &&
            other.clientId == clientId &&
            other.responseTimeout == responseTimeout &&
            other.secure == secure &&
            other.mode == mode &&
            other.relayDeviceId == relayDeviceId &&
            other.relayToken == relayToken &&
            other.relayPath == relayPath &&
            other.otaSettings == otaSettings;
  }

  @override
  int get hashCode {
    return Object.hash(
      host,
      port,
      clientId,
      responseTimeout,
      secure,
      mode,
      relayDeviceId,
      relayToken,
      relayPath,
      otaSettings,
    );
  }
}
