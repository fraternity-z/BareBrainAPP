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
      'showMessageTimestamps': settings.showMessageTimestamps,
      'showMessageActions': settings.showMessageActions,
      'compactMessageSpacing': settings.compactMessageSpacing,
      'selectableMessageText': settings.selectableMessageText,
      'hapticFeedback': settings.hapticFeedback,
      'messageBackground': settings.messageBackground.name,
      'appFont': settings.appFont.name,
      'codeFont': settings.codeFont.name,
      'messageFontScale': settings.messageFontScale,
      'autoScrollDelayMs': settings.autoScrollDelay.inMilliseconds,
      'backgroundMaskOpacity': settings.backgroundMaskOpacity,
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
      themePreset: _enumValue(
        ChatThemePreset.values,
        value['themePreset'],
        defaults.themePreset,
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
      backgroundMaskOpacity: _doubleValue(
        value['backgroundMaskOpacity'],
        defaults.backgroundMaskOpacity,
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
