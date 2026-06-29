enum ChatColorMode {
  system('跟随系统'),
  light('浅色'),
  dark('深色');

  const ChatColorMode(this.label);

  final String label;
}

enum ChatThemePreset {
  monochrome('黑白灰', '克制的中性色强调，适合纯粹黑白灰界面'),
  defaultTheme('默认主题', '简洁现代的默认设计风格'),
  claude('Claude 风格', '温暖优雅的 Claude AI 设计风格'),
  natural('自然风格', '2025年流行的自然系大地色调设计'),
  futureTech('未来科技', '2025年流行的科技感设计，冷色调与玻璃态效果'),
  gentleGradient('柔和渐变', '2025年流行的柔和渐变设计，温暖舒适的视觉体验'),
  ocean('海洋风格', '2025年流行的海洋蓝绿色系，清新舒适的视觉体验'),
  sunset('日落风格', '2025年流行的日落色系，温暖浪漫的视觉氛围'),
  cinnamonBoard('肉桂板岩', '2025年流行趋势：深邃温暖的色调，带来内心的平静'),
  horizonGreen('地平线绿', '2025年日本代表色：带黄调的绿色，象征希望与自然'),
  cherryCoding('樱桃编码', '2025年流行趋势：深樱桃红色，传达热情与活力');

  const ChatThemePreset(this.label, this.description);

  final String label;
  final String description;
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
    this.themePreset = ChatThemePreset.defaultTheme,
    this.showMessageAvatars = true,
    this.showMessageAuthorNames = false,
    this.showMessageTimestamps = true,
    this.showMessageActions = true,
    this.compactMessageSpacing = false,
    this.selectableMessageText = true,
    this.inlineMathRendering = true,
    this.mathEquationRendering = true,
    this.userMessageMarkdownRendering = true,
    this.assistantMessageMarkdownRendering = true,
    this.autoFoldCodeBlocks = false,
    this.mobileCodeBlockAutoWrap = false,
    this.deleteMessagesBelowOnRegenerate = false,
    this.confirmBeforeRegenerate = true,
    this.showMessageNavigationButtons = true,
    this.showConversationListDates = false,
    this.keepDrawerOpenOnConversationSelect = false,
    this.sendMessageWithEnterKey = true,
    this.hapticFeedback = true,
    this.messageBackground = ChatMessageBackground.standard,
    this.appFont = ChatAppFont.system,
    this.codeFont = ChatCodeFont.system,
    this.messageFontScale = 1.10,
    this.autoScrollDelay = const Duration(seconds: 8),
  }) : assert(messageFontScale >= 0.9 && messageFontScale <= 1.4);

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
  final bool assistantMessageMarkdownRendering;
  final bool autoFoldCodeBlocks;
  final bool mobileCodeBlockAutoWrap;
  final bool deleteMessagesBelowOnRegenerate;
  final bool confirmBeforeRegenerate;
  final bool showMessageNavigationButtons;
  final bool showConversationListDates;
  final bool keepDrawerOpenOnConversationSelect;
  final bool sendMessageWithEnterKey;
  final bool hapticFeedback;
  final ChatMessageBackground messageBackground;
  final ChatAppFont appFont;
  final ChatCodeFont codeFont;
  final double messageFontScale;
  final Duration autoScrollDelay;

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
    bool? assistantMessageMarkdownRendering,
    bool? autoFoldCodeBlocks,
    bool? mobileCodeBlockAutoWrap,
    bool? deleteMessagesBelowOnRegenerate,
    bool? confirmBeforeRegenerate,
    bool? showMessageNavigationButtons,
    bool? showConversationListDates,
    bool? keepDrawerOpenOnConversationSelect,
    bool? sendMessageWithEnterKey,
    bool? hapticFeedback,
    ChatMessageBackground? messageBackground,
    ChatAppFont? appFont,
    ChatCodeFont? codeFont,
    double? messageFontScale,
    Duration? autoScrollDelay,
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
      assistantMessageMarkdownRendering: assistantMessageMarkdownRendering ??
          this.assistantMessageMarkdownRendering,
      autoFoldCodeBlocks: autoFoldCodeBlocks ?? this.autoFoldCodeBlocks,
      mobileCodeBlockAutoWrap:
          mobileCodeBlockAutoWrap ?? this.mobileCodeBlockAutoWrap,
      deleteMessagesBelowOnRegenerate: deleteMessagesBelowOnRegenerate ??
          this.deleteMessagesBelowOnRegenerate,
      confirmBeforeRegenerate:
          confirmBeforeRegenerate ?? this.confirmBeforeRegenerate,
      showMessageNavigationButtons:
          showMessageNavigationButtons ?? this.showMessageNavigationButtons,
      showConversationListDates:
          showConversationListDates ?? this.showConversationListDates,
      keepDrawerOpenOnConversationSelect: keepDrawerOpenOnConversationSelect ??
          this.keepDrawerOpenOnConversationSelect,
      sendMessageWithEnterKey:
          sendMessageWithEnterKey ?? this.sendMessageWithEnterKey,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      messageBackground: messageBackground ?? this.messageBackground,
      appFont: appFont ?? this.appFont,
      codeFont: codeFont ?? this.codeFont,
      messageFontScale: _clampFontScale(
        messageFontScale ?? this.messageFontScale,
      ),
      autoScrollDelay: _clampDelay(autoScrollDelay ?? this.autoScrollDelay),
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

  static double _clampFontScale(double value) {
    return value.clamp(0.9, 1.4).toDouble();
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
            other.assistantMessageMarkdownRendering ==
                assistantMessageMarkdownRendering &&
            other.autoFoldCodeBlocks == autoFoldCodeBlocks &&
            other.mobileCodeBlockAutoWrap == mobileCodeBlockAutoWrap &&
            other.deleteMessagesBelowOnRegenerate ==
                deleteMessagesBelowOnRegenerate &&
            other.confirmBeforeRegenerate == confirmBeforeRegenerate &&
            other.showMessageNavigationButtons ==
                showMessageNavigationButtons &&
            other.showConversationListDates == showConversationListDates &&
            other.keepDrawerOpenOnConversationSelect ==
                keepDrawerOpenOnConversationSelect &&
            other.sendMessageWithEnterKey == sendMessageWithEnterKey &&
            other.hapticFeedback == hapticFeedback &&
            other.messageBackground == messageBackground &&
            other.appFont == appFont &&
            other.codeFont == codeFont &&
            other.messageFontScale == messageFontScale &&
            other.autoScrollDelay == autoScrollDelay;
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
      assistantMessageMarkdownRendering,
      autoFoldCodeBlocks,
      mobileCodeBlockAutoWrap,
      deleteMessagesBelowOnRegenerate,
      confirmBeforeRegenerate,
      showMessageNavigationButtons,
      showConversationListDates,
      keepDrawerOpenOnConversationSelect,
      sendMessageWithEnterKey,
      hapticFeedback,
      messageBackground,
      appFont,
      codeFont,
      messageFontScale,
      autoScrollDelay,
    ]);
  }
}
