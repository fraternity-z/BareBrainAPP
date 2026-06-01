enum ChatColorMode {
  system('跟随系统'),
  light('浅色'),
  dark('深色');

  const ChatColorMode(this.label);

  final String label;
}

enum ChatThemePreset {
  seaFog('浅灰'),
  graphite('岩灰'),
  warmSun('深灰');

  const ChatThemePreset(this.label);

  final String label;
}

enum ChatMessageBackground {
  standard('默认'),
  soft('柔和'),
  plain('简洁');

  const ChatMessageBackground(this.label);

  final String label;
}

enum ChatAppFont {
  system('系统默认', null),
  sans('屏显黑体', 'Microsoft YaHei'),
  serif('宋体', 'SimSun');

  const ChatAppFont(this.label, this.fontFamily);

  final String label;
  final String? fontFamily;
}

enum ChatCodeFont {
  system('系统默认', null),
  mono('等宽', 'Consolas'),
  serif('衬线', 'Courier New');

  const ChatCodeFont(this.label, this.fontFamily);

  final String label;
  final String? fontFamily;
}

class ChatDisplaySettings {
  const ChatDisplaySettings({
    this.colorMode = ChatColorMode.system,
    this.themePreset = ChatThemePreset.graphite,
    this.showMessageAvatars = true,
    this.showMessageAuthorNames = false,
    this.showMessageTimestamps = true,
    this.showMessageActions = true,
    this.compactMessageSpacing = false,
    this.selectableMessageText = true,
    this.inlineMathRendering = true,
    this.mathEquationRendering = true,
    this.userMessageMarkdownRendering = true,
    this.reasoningMarkdownRendering = true,
    this.assistantMessageMarkdownRendering = true,
    this.autoFoldCodeBlocks = false,
    this.mobileCodeBlockAutoWrap = false,
    this.hapticFeedback = true,
    this.messageBackground = ChatMessageBackground.standard,
    this.appFont = ChatAppFont.system,
    this.codeFont = ChatCodeFont.system,
    this.messageFontScale = 1.10,
    this.autoScrollDelay = const Duration(seconds: 8),
    this.backgroundMaskOpacity = 1.0,
  })  : assert(messageFontScale >= 0.9 && messageFontScale <= 1.4),
        assert(backgroundMaskOpacity >= 0 && backgroundMaskOpacity <= 1);

  final ChatColorMode colorMode;
  final ChatThemePreset themePreset;
  final bool showMessageAvatars;
  final bool showMessageAuthorNames;
  final bool showMessageTimestamps;
  final bool showMessageActions;
  final bool compactMessageSpacing;
  final bool selectableMessageText;
  final bool inlineMathRendering;
  final bool mathEquationRendering;
  final bool userMessageMarkdownRendering;
  final bool reasoningMarkdownRendering;
  final bool assistantMessageMarkdownRendering;
  final bool autoFoldCodeBlocks;
  final bool mobileCodeBlockAutoWrap;
  final bool hapticFeedback;
  final ChatMessageBackground messageBackground;
  final ChatAppFont appFont;
  final ChatCodeFont codeFont;
  final double messageFontScale;
  final Duration autoScrollDelay;
  final double backgroundMaskOpacity;

  ChatDisplaySettings copyWith({
    ChatColorMode? colorMode,
    ChatThemePreset? themePreset,
    bool? showMessageAvatars,
    bool? showMessageAuthorNames,
    bool? showMessageTimestamps,
    bool? showMessageActions,
    bool? compactMessageSpacing,
    bool? selectableMessageText,
    bool? inlineMathRendering,
    bool? mathEquationRendering,
    bool? userMessageMarkdownRendering,
    bool? reasoningMarkdownRendering,
    bool? assistantMessageMarkdownRendering,
    bool? autoFoldCodeBlocks,
    bool? mobileCodeBlockAutoWrap,
    bool? hapticFeedback,
    ChatMessageBackground? messageBackground,
    ChatAppFont? appFont,
    ChatCodeFont? codeFont,
    double? messageFontScale,
    Duration? autoScrollDelay,
    double? backgroundMaskOpacity,
  }) {
    return ChatDisplaySettings(
      colorMode: colorMode ?? this.colorMode,
      themePreset: themePreset ?? this.themePreset,
      showMessageAvatars: showMessageAvatars ?? this.showMessageAvatars,
      showMessageAuthorNames:
          showMessageAuthorNames ?? this.showMessageAuthorNames,
      showMessageTimestamps:
          showMessageTimestamps ?? this.showMessageTimestamps,
      showMessageActions: showMessageActions ?? this.showMessageActions,
      compactMessageSpacing:
          compactMessageSpacing ?? this.compactMessageSpacing,
      selectableMessageText:
          selectableMessageText ?? this.selectableMessageText,
      inlineMathRendering: inlineMathRendering ?? this.inlineMathRendering,
      mathEquationRendering:
          mathEquationRendering ?? this.mathEquationRendering,
      userMessageMarkdownRendering:
          userMessageMarkdownRendering ?? this.userMessageMarkdownRendering,
      reasoningMarkdownRendering:
          reasoningMarkdownRendering ?? this.reasoningMarkdownRendering,
      assistantMessageMarkdownRendering: assistantMessageMarkdownRendering ??
          this.assistantMessageMarkdownRendering,
      autoFoldCodeBlocks: autoFoldCodeBlocks ?? this.autoFoldCodeBlocks,
      mobileCodeBlockAutoWrap:
          mobileCodeBlockAutoWrap ?? this.mobileCodeBlockAutoWrap,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      messageBackground: messageBackground ?? this.messageBackground,
      appFont: appFont ?? this.appFont,
      codeFont: codeFont ?? this.codeFont,
      messageFontScale: _clampFontScale(
        messageFontScale ?? this.messageFontScale,
      ),
      autoScrollDelay: _clampDelay(autoScrollDelay ?? this.autoScrollDelay),
      backgroundMaskOpacity: _clampOpacity(
        backgroundMaskOpacity ?? this.backgroundMaskOpacity,
      ),
    );
  }

  String get messageFontScaleLabel {
    return '${(messageFontScale * 100).round()}%';
  }

  String get autoScrollDelayLabel {
    if (autoScrollDelay == Duration.zero) {
      return '立即';
    }

    return '${autoScrollDelay.inSeconds}s';
  }

  String get backgroundMaskOpacityLabel {
    return '${(backgroundMaskOpacity * 100).round()}%';
  }

  static double _clampFontScale(double value) {
    return value.clamp(0.9, 1.4).toDouble();
  }

  static double _clampOpacity(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }

  static Duration _clampDelay(Duration value) {
    if (value < Duration.zero) {
      return Duration.zero;
    }

    if (value > const Duration(seconds: 60)) {
      return const Duration(seconds: 60);
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChatDisplaySettings &&
            other.colorMode == colorMode &&
            other.themePreset == themePreset &&
            other.showMessageAvatars == showMessageAvatars &&
            other.showMessageAuthorNames == showMessageAuthorNames &&
            other.showMessageTimestamps == showMessageTimestamps &&
            other.showMessageActions == showMessageActions &&
            other.compactMessageSpacing == compactMessageSpacing &&
            other.selectableMessageText == selectableMessageText &&
            other.inlineMathRendering == inlineMathRendering &&
            other.mathEquationRendering == mathEquationRendering &&
            other.userMessageMarkdownRendering ==
                userMessageMarkdownRendering &&
            other.reasoningMarkdownRendering == reasoningMarkdownRendering &&
            other.assistantMessageMarkdownRendering ==
                assistantMessageMarkdownRendering &&
            other.autoFoldCodeBlocks == autoFoldCodeBlocks &&
            other.mobileCodeBlockAutoWrap == mobileCodeBlockAutoWrap &&
            other.hapticFeedback == hapticFeedback &&
            other.messageBackground == messageBackground &&
            other.appFont == appFont &&
            other.codeFont == codeFont &&
            other.messageFontScale == messageFontScale &&
            other.autoScrollDelay == autoScrollDelay &&
            other.backgroundMaskOpacity == backgroundMaskOpacity;
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      colorMode,
      themePreset,
      showMessageAvatars,
      showMessageAuthorNames,
      showMessageTimestamps,
      showMessageActions,
      compactMessageSpacing,
      selectableMessageText,
      inlineMathRendering,
      mathEquationRendering,
      userMessageMarkdownRendering,
      reasoningMarkdownRendering,
      assistantMessageMarkdownRendering,
      autoFoldCodeBlocks,
      mobileCodeBlockAutoWrap,
      hapticFeedback,
      messageBackground,
      appFont,
      codeFont,
      messageFontScale,
      autoScrollDelay,
      backgroundMaskOpacity,
    ]);
  }
}
