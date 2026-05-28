import 'chat_ota_settings.dart';

class ChatConnectionSettings {
  const ChatConnectionSettings({
    required this.host,
    required this.port,
    required this.clientId,
    required this.responseTimeout,
    this.secure = false,
    this.otaSettings = const ChatOtaSettings(),
  });

  final String host;
  final int port;
  final String clientId;
  final Duration responseTimeout;
  final bool secure;
  final ChatOtaSettings otaSettings;

  Uri get websocketUri {
    return Uri(
      scheme: secure ? 'wss' : 'ws',
      host: host,
      port: port,
      path: '/',
    );
  }

  ChatConnectionSettings copyWith({
    String? host,
    int? port,
    String? clientId,
    Duration? responseTimeout,
    bool? secure,
    ChatOtaSettings? otaSettings,
  }) {
    return ChatConnectionSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      responseTimeout: responseTimeout ?? this.responseTimeout,
      secure: secure ?? this.secure,
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
      otaSettings,
    );
  }
}
