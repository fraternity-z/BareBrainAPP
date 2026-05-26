class ChatConnectionSettings {
  const ChatConnectionSettings({
    required this.host,
    required this.port,
    required this.clientId,
    required this.responseTimeout,
    this.secure = false,
  });

  final String host;
  final int port;
  final String clientId;
  final Duration responseTimeout;
  final bool secure;

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
  }) {
    return ChatConnectionSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      responseTimeout: responseTimeout ?? this.responseTimeout,
      secure: secure ?? this.secure,
    );
  }
}
