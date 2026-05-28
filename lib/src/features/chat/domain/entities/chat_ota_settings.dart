class ChatOtaSettings {
  const ChatOtaSettings({
    this.versionPath = '/ota/version',
    this.firmwarePath = '/ota/firmware',
    this.channel = 'stable',
    this.requestTimeout = const Duration(seconds: 120),
    this.autoCheck = false,
  });

  final String versionPath;
  final String firmwarePath;
  final String channel;
  final Duration requestTimeout;
  final bool autoCheck;

  ChatOtaSettings copyWith({
    String? versionPath,
    String? firmwarePath,
    String? channel,
    Duration? requestTimeout,
    bool? autoCheck,
  }) {
    return ChatOtaSettings(
      versionPath: versionPath ?? this.versionPath,
      firmwarePath: firmwarePath ?? this.firmwarePath,
      channel: channel ?? this.channel,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      autoCheck: autoCheck ?? this.autoCheck,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatOtaSettings &&
            other.versionPath == versionPath &&
            other.firmwarePath == firmwarePath &&
            other.channel == channel &&
            other.requestTimeout == requestTimeout &&
            other.autoCheck == autoCheck;
  }

  @override
  int get hashCode {
    return Object.hash(
      versionPath,
      firmwarePath,
      channel,
      requestTimeout,
      autoCheck,
    );
  }
}
