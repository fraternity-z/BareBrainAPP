import 'dart:convert';

import '../../domain/entities/chat_display_settings.dart';

class ChatDisplaySettingsCodec {
  const ChatDisplaySettingsCodec._();

  static String encode(ChatDisplaySettings settings) {
    return jsonEncode(toJson(settings));
  }

  static ChatDisplaySettings decode(String source) {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('显示设置格式无效');
    }

    return fromJson(value);
  }

  static Map<String, dynamic> toJson(ChatDisplaySettings settings) {
    return <String, dynamic>{
      'colorMode': settings.colorMode.name,
      'themePreset': settings.themePreset.name,
      'showMessageAvatars': settings.showMessageAvatars,
      'showMessageAuthorNames': settings.showMessageAuthorNames,
      'showMessageTimestamps': settings.showMessageTimestamps,
      'showMessageActions': settings.showMessageActions,
      'compactMessageSpacing': settings.compactMessageSpacing,
      'selectableMessageText': settings.selectableMessageText,
      'inlineMathRendering': settings.inlineMathRendering,
      'mathEquationRendering': settings.mathEquationRendering,
      'userMessageMarkdownRendering': settings.userMessageMarkdownRendering,
      'assistantMessageMarkdownRendering':
          settings.assistantMessageMarkdownRendering,
      'autoFoldCodeBlocks': settings.autoFoldCodeBlocks,
      'mobileCodeBlockAutoWrap': settings.mobileCodeBlockAutoWrap,
      'deleteMessagesBelowOnRegenerate':
          settings.deleteMessagesBelowOnRegenerate,
      'confirmBeforeRegenerate': settings.confirmBeforeRegenerate,
      'showMessageNavigationButtons': settings.showMessageNavigationButtons,
      'showConversationListDates': settings.showConversationListDates,
      'keepDrawerOpenOnConversationSelect':
          settings.keepDrawerOpenOnConversationSelect,
      'sendMessageWithEnterKey': settings.sendMessageWithEnterKey,
      'hapticFeedback': settings.hapticFeedback,
      'messageBackground': settings.messageBackground.name,
      'appFont': settings.appFont.name,
      'codeFont': settings.codeFont.name,
      'messageFontScale': settings.messageFontScale,
      'autoScrollDelayMs': settings.autoScrollDelay.inMilliseconds,
    };
  }

  static ChatDisplaySettings fromJson(Map<String, dynamic> value) {
    const defaults = ChatDisplaySettings();
    return defaults.copyWith(
      colorMode: _enumValue(
        ChatColorMode.values,
        value['colorMode'],
        defaults.colorMode,
      ),
      themePreset: _themePresetValue(
        value['themePreset'],
        defaults.themePreset,
      ),
      showMessageAvatars: _boolValue(
        value['showMessageAvatars'],
        defaults.showMessageAvatars,
      ),
      showMessageAuthorNames: _boolValue(
        value['showMessageAuthorNames'],
        defaults.showMessageAuthorNames,
      ),
      showMessageTimestamps: _boolValue(
        value['showMessageTimestamps'],
        defaults.showMessageTimestamps,
      ),
      showMessageActions: _boolValue(
        value['showMessageActions'],
        defaults.showMessageActions,
      ),
      compactMessageSpacing: _boolValue(
        value['compactMessageSpacing'],
        defaults.compactMessageSpacing,
      ),
      selectableMessageText: _boolValue(
        value['selectableMessageText'],
        defaults.selectableMessageText,
      ),
      inlineMathRendering: _boolValue(
        value['inlineMathRendering'],
        defaults.inlineMathRendering,
      ),
      mathEquationRendering: _boolValue(
        value['mathEquationRendering'],
        defaults.mathEquationRendering,
      ),
      userMessageMarkdownRendering: _boolValue(
        value['userMessageMarkdownRendering'],
        defaults.userMessageMarkdownRendering,
      ),
      assistantMessageMarkdownRendering: _boolValue(
        value['assistantMessageMarkdownRendering'],
        defaults.assistantMessageMarkdownRendering,
      ),
      autoFoldCodeBlocks: _boolValue(
        value['autoFoldCodeBlocks'],
        defaults.autoFoldCodeBlocks,
      ),
      mobileCodeBlockAutoWrap: _boolValue(
        value['mobileCodeBlockAutoWrap'],
        defaults.mobileCodeBlockAutoWrap,
      ),
      deleteMessagesBelowOnRegenerate: _boolValue(
        value['deleteMessagesBelowOnRegenerate'],
        defaults.deleteMessagesBelowOnRegenerate,
      ),
      confirmBeforeRegenerate: _boolValue(
        value['confirmBeforeRegenerate'],
        defaults.confirmBeforeRegenerate,
      ),
      showMessageNavigationButtons: _boolValue(
        value['showMessageNavigationButtons'],
        defaults.showMessageNavigationButtons,
      ),
      showConversationListDates: _boolValue(
        value['showConversationListDates'],
        defaults.showConversationListDates,
      ),
      keepDrawerOpenOnConversationSelect: _boolValue(
        value['keepDrawerOpenOnConversationSelect'],
        defaults.keepDrawerOpenOnConversationSelect,
      ),
      sendMessageWithEnterKey: _boolValue(
        value['sendMessageWithEnterKey'],
        defaults.sendMessageWithEnterKey,
      ),
      hapticFeedback: _boolValue(
        value['hapticFeedback'],
        defaults.hapticFeedback,
      ),
      messageBackground: _enumValue(
        ChatMessageBackground.values,
        value['messageBackground'],
        defaults.messageBackground,
      ),
      appFont: _enumValue(
        ChatAppFont.values,
        value['appFont'],
        defaults.appFont,
      ),
      codeFont: _enumValue(
        ChatCodeFont.values,
        value['codeFont'],
        defaults.codeFont,
      ),
      messageFontScale: _doubleValue(
        value['messageFontScale'],
        defaults.messageFontScale,
      ),
      autoScrollDelay: Duration(
        milliseconds: _intValue(
          value['autoScrollDelayMs'],
          defaults.autoScrollDelay.inMilliseconds,
        ),
      ),
    );
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    Object? source,
    T fallback,
  ) {
    if (source is! String) {
      return fallback;
    }

    for (final value in values) {
      if (value.name == source) {
        return value;
      }
    }

    return fallback;
  }

  static ChatThemePreset _themePresetValue(
    Object? source,
    ChatThemePreset fallback,
  ) {
    final preset = _enumValue(ChatThemePreset.values, source, fallback);
    if (preset != fallback || source is! String) {
      return preset;
    }

    return switch (source) {
      'seaFog' => ChatThemePreset.ocean,
      'graphite' => ChatThemePreset.monochrome,
      'warmSun' => ChatThemePreset.cinnamonBoard,
      _ => fallback,
    };
  }

  static bool _boolValue(Object? source, bool fallback) {
    return source is bool ? source : fallback;
  }

  static int _intValue(Object? source, int fallback) {
    return source is int ? source : fallback;
  }

  static double _doubleValue(Object? source, double fallback) {
    if (source is int) {
      return source.toDouble();
    }

    return source is double ? source : fallback;
  }
}
