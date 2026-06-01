import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_message.dart';
import '../widgets/message_bubble.dart';
import 'settings_components.dart';

class DisplaySettingsPage extends StatefulWidget {
  const DisplaySettingsPage({
    this.settings = const ChatDisplaySettings(),
    this.onChanged,
    super.key,
  });

  final ChatDisplaySettings settings;
  final ValueChanged<ChatDisplaySettings>? onChanged;

  @override
  State<DisplaySettingsPage> createState() => _DisplaySettingsPageState();
}

class _DisplaySettingsPageState extends State<DisplaySettingsPage> {
  late ChatDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant DisplaySettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '显示设置',
      actions: <Widget>[
        IconButton(
          key: const Key('display_reset_button'),
          tooltip: '恢复默认',
          onPressed: _resetSettings,
          icon: const Icon(Icons.restart_alt, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          _DisplaySettingsCard(
            children: <Widget>[
              SettingsRow(
                key: const Key('display_theme_preset_row'),
                icon: Icons.palette_outlined,
                title: '主题设置',
                value: _settings.themePreset.label,
                onTap: _openThemeSettings,
              ),
              SettingsRow(
                key: const Key('display_chat_items_row'),
                icon: Icons.chat_bubble_outline,
                title: '聊天项显示',
                value: _chatItemsSummary(),
                onTap: _openChatItemSettings,
              ),
              SettingsRow(
                key: const Key('display_rendering_row'),
                icon: Icons.format_color_text_outlined,
                title: '渲染设置',
                value: _renderingSummary(),
                onTap: _openRenderingSettings,
              ),
              SettingsRow(
                key: const Key('display_behavior_row'),
                icon: Icons.dark_mode_outlined,
                title: '行为与启动',
                value: _behaviorSummary(),
                onTap: _openBehaviorSettings,
              ),
              _DisplaySwitchRow(
                key: const Key('display_haptic_feedback_row'),
                switchKey: const Key('display_haptic_feedback_switch'),
                icon: Icons.vibration_outlined,
                title: '触觉反馈',
                value: _settings.hapticFeedback,
                onChanged: (value) {
                  _update(_settings.copyWith(hapticFeedback: value));
                },
              ),
              SettingsRow(
                key: const Key('display_message_background_row'),
                icon: Icons.chat_outlined,
                title: '聊天消息背景',
                value: _settings.messageBackground.label,
                onTap: () => unawaited(_openMessageBackground()),
              ),
              SettingsRow(
                key: const Key('display_app_font_row'),
                icon: Icons.text_fields,
                title: '应用字体',
                value: _settings.appFont.label,
                onTap: () => unawaited(_openAppFont()),
              ),
              SettingsRow(
                key: const Key('display_code_font_row'),
                icon: Icons.code,
                title: '代码字体',
                value: _settings.codeFont.label,
                onTap: () => unawaited(_openCodeFont()),
              ),
              SettingsRow(
                key: const Key('display_message_font_scale_row'),
                icon: Icons.text_increase,
                title: '聊天字体大小',
                value: _settings.messageFontScaleLabel,
                onTap: () => unawaited(_openMessageFontScale()),
              ),
              SettingsRow(
                key: const Key('display_auto_scroll_delay_row'),
                icon: Icons.arrow_downward,
                title: '自动回到底部延迟',
                value: _settings.autoScrollDelayLabel,
                onTap: () => unawaited(_openAutoScrollDelay()),
              ),
              SettingsRow(
                key: const Key('display_background_mask_row'),
                icon: Icons.image_outlined,
                title: '聊天背景遮罩透明度',
                value: _settings.backgroundMaskOpacityLabel,
                onTap: () => unawaited(_openBackgroundMaskOpacity()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMessageBackground() {
    return _showChoiceSheet<ChatMessageBackground>(
      title: '聊天消息背景',
      selected: _settings.messageBackground,
      items: ChatMessageBackground.values.map((background) {
        return _ChoiceItem<ChatMessageBackground>(
          key: 'message_background_${background.name}',
          label: background.label,
          value: background,
        );
      }).toList(),
      onSelected: (background) {
        _update(_settings.copyWith(messageBackground: background));
      },
    );
  }

  Future<void> _openAppFont() {
    return _showChoiceSheet<ChatAppFont>(
      title: '应用字体',
      selected: _settings.appFont,
      items: ChatAppFont.values.map((font) {
        return _ChoiceItem<ChatAppFont>(
          key: 'app_font_${font.name}',
          label: font.label,
          value: font,
        );
      }).toList(),
      onSelected: (font) {
        _update(_settings.copyWith(appFont: font));
      },
    );
  }

  Future<void> _openCodeFont() {
    return _showChoiceSheet<ChatCodeFont>(
      title: '代码字体',
      selected: _settings.codeFont,
      items: ChatCodeFont.values.map((font) {
        return _ChoiceItem<ChatCodeFont>(
          key: 'code_font_${font.name}',
          label: font.label,
          value: font,
        );
      }).toList(),
      onSelected: (font) {
        _update(_settings.copyWith(codeFont: font));
      },
    );
  }

  Future<void> _openMessageFontScale() {
    return _showChoiceSheet<double>(
      title: '聊天字体大小',
      selected: _settings.messageFontScale,
      items: const <_ChoiceItem<double>>[
        _ChoiceItem<double>(key: 'message_font_90', label: '90%', value: 0.90),
        _ChoiceItem<double>(key: 'message_font_100', label: '100%', value: 1.0),
        _ChoiceItem<double>(key: 'message_font_110', label: '110%', value: 1.1),
        _ChoiceItem<double>(
            key: 'message_font_125', label: '125%', value: 1.25),
        _ChoiceItem<double>(key: 'message_font_140', label: '140%', value: 1.4),
      ],
      onSelected: (scale) {
        _update(_settings.copyWith(messageFontScale: scale));
      },
    );
  }

  Future<void> _openAutoScrollDelay() {
    return _showChoiceSheet<Duration>(
      title: '自动回到底部延迟',
      selected: _settings.autoScrollDelay,
      items: const <_ChoiceItem<Duration>>[
        _ChoiceItem<Duration>(
          key: 'auto_scroll_0',
          label: '立即',
          value: Duration.zero,
        ),
        _ChoiceItem<Duration>(
          key: 'auto_scroll_2',
          label: '2s',
          value: Duration(seconds: 2),
        ),
        _ChoiceItem<Duration>(
          key: 'auto_scroll_5',
          label: '5s',
          value: Duration(seconds: 5),
        ),
        _ChoiceItem<Duration>(
          key: 'auto_scroll_8',
          label: '8s',
          value: Duration(seconds: 8),
        ),
        _ChoiceItem<Duration>(
          key: 'auto_scroll_12',
          label: '12s',
          value: Duration(seconds: 12),
        ),
      ],
      onSelected: (delay) {
        _update(_settings.copyWith(autoScrollDelay: delay));
      },
    );
  }

  Future<void> _openBackgroundMaskOpacity() {
    return _showChoiceSheet<double>(
      title: '聊天背景遮罩透明度',
      selected: _settings.backgroundMaskOpacity,
      items: const <_ChoiceItem<double>>[
        _ChoiceItem<double>(key: 'mask_0', label: '0%', value: 0.0),
        _ChoiceItem<double>(key: 'mask_50', label: '50%', value: 0.5),
        _ChoiceItem<double>(key: 'mask_75', label: '75%', value: 0.75),
        _ChoiceItem<double>(key: 'mask_100', label: '100%', value: 1.0),
      ],
      onSelected: (opacity) {
        _update(_settings.copyWith(backgroundMaskOpacity: opacity));
      },
    );
  }

  void _openThemeSettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ThemeDisplaySettingsPage(
            settings: _settings,
            onChanged: _update,
          ),
        ),
      ),
    );
  }

  void _openChatItemSettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => ChatItemsDisplaySettingsPage(
            settings: _settings,
            onChanged: _update,
          ),
        ),
      ),
    );
  }

  void _openRenderingSettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => RenderingDisplaySettingsPage(
            settings: _settings,
            onChanged: _update,
          ),
        ),
      ),
    );
  }

  void _openBehaviorSettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => BehaviorDisplaySettingsPage(
            settings: _settings,
            onChanged: _update,
          ),
        ),
      ),
    );
  }

  Future<void> _showChoiceSheet<T>({
    required String title,
    required T selected,
    required List<_ChoiceItem<T>> items,
    required ValueChanged<T> onSelected,
  }) async {
    final next = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ChoiceSheet<T>(
          title: title,
          selected: selected,
          items: items,
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    onSelected(next);
  }

  String _chatItemsSummary() {
    final enabled = <String>[
      if (_settings.showMessageAvatars) '头像',
      if (_settings.showMessageAuthorNames) '名称',
      if (_settings.showMessageTimestamps) '时间',
      if (_settings.showMessageActions) '操作',
      if (_settings.compactMessageSpacing) '紧凑',
    ];
    if (enabled.isEmpty) {
      return '极简';
    }

    return enabled.take(3).join(' · ');
  }

  String _renderingSummary() {
    final text = _settings.selectableMessageText ? '可选文本' : '普通文本';
    return '$text · ${_settings.messageFontScaleLabel}';
  }

  String _behaviorSummary() {
    final feedback = _settings.hapticFeedback ? '触觉' : '无触觉';
    return '${_settings.colorMode.label} · $feedback';
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  void _resetSettings() {
    _update(const ChatDisplaySettings());
  }
}

class ThemeDisplaySettingsPage extends StatefulWidget {
  const ThemeDisplaySettingsPage({
    this.settings = const ChatDisplaySettings(),
    this.onChanged,
    super.key,
  });

  final ChatDisplaySettings settings;
  final ValueChanged<ChatDisplaySettings>? onChanged;

  @override
  State<ThemeDisplaySettingsPage> createState() =>
      _ThemeDisplaySettingsPageState();
}

class _ThemeDisplaySettingsPageState extends State<ThemeDisplaySettingsPage> {
  late ChatDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant ThemeDisplaySettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '主题设置',
      actions: <Widget>[
        IconButton(
          key: const Key('theme_reset_button'),
          tooltip: '恢复默认',
          onPressed: _resetSettings,
          icon: const Icon(Icons.restart_alt, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _ThemePreviewCard(settings: _settings),
          ),
          SettingsSection(
            title: '主题',
            children: <Widget>[
              SettingsRow(
                key: const Key('theme_preset_row'),
                icon: Icons.palette_outlined,
                title: '主题预设',
                value: _settings.themePreset.label,
                onTap: () => unawaited(_openThemePreset()),
              ),
              SettingsRow(
                key: const Key('theme_color_mode_row'),
                icon: Icons.light_mode_outlined,
                title: '颜色模式',
                value: _settings.colorMode.label,
                onTap: () => unawaited(_openColorMode()),
              ),
            ],
          ),
          SettingsSection(
            title: '背景',
            children: <Widget>[
              SettingsRow(
                key: const Key('theme_background_mask_row'),
                icon: Icons.image_outlined,
                title: '聊天背景遮罩透明度',
                value: _settings.backgroundMaskOpacityLabel,
                onTap: () => unawaited(_openBackgroundMaskOpacity()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openThemePreset() {
    return _showChoiceSheet<ChatThemePreset>(
      title: '主题预设',
      selected: _settings.themePreset,
      items: ChatThemePreset.values.map((preset) {
        return _ChoiceItem<ChatThemePreset>(
          key: 'theme_preset_${preset.name}',
          label: preset.label,
          value: preset,
        );
      }).toList(),
      onSelected: (preset) {
        _update(_settings.copyWith(themePreset: preset));
      },
    );
  }

  Future<void> _openColorMode() {
    return _showChoiceSheet<ChatColorMode>(
      title: '颜色模式',
      selected: _settings.colorMode,
      items: ChatColorMode.values.map((mode) {
        return _ChoiceItem<ChatColorMode>(
          key: 'theme_color_mode_${mode.name}',
          label: mode.label,
          value: mode,
        );
      }).toList(),
      onSelected: (mode) {
        _update(_settings.copyWith(colorMode: mode));
      },
    );
  }

  Future<void> _openBackgroundMaskOpacity() {
    return _showChoiceSheet<double>(
      title: '聊天背景遮罩透明度',
      selected: _settings.backgroundMaskOpacity,
      items: const <_ChoiceItem<double>>[
        _ChoiceItem<double>(
          key: 'theme_mask_0',
          label: '0%',
          value: 0.0,
        ),
        _ChoiceItem<double>(
          key: 'theme_mask_50',
          label: '50%',
          value: 0.5,
        ),
        _ChoiceItem<double>(
          key: 'theme_mask_75',
          label: '75%',
          value: 0.75,
        ),
        _ChoiceItem<double>(
          key: 'theme_mask_100',
          label: '100%',
          value: 1.0,
        ),
      ],
      onSelected: (opacity) {
        _update(_settings.copyWith(backgroundMaskOpacity: opacity));
      },
    );
  }

  Future<void> _showChoiceSheet<T>({
    required String title,
    required T selected,
    required List<_ChoiceItem<T>> items,
    required ValueChanged<T> onSelected,
  }) async {
    final next = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ChoiceSheet<T>(
          title: title,
          selected: selected,
          items: items,
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    onSelected(next);
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  void _resetSettings() {
    const defaults = ChatDisplaySettings();
    _update(
      _settings.copyWith(
        colorMode: defaults.colorMode,
        themePreset: defaults.themePreset,
        backgroundMaskOpacity: defaults.backgroundMaskOpacity,
      ),
    );
  }
}

class RenderingDisplaySettingsPage extends StatefulWidget {
  const RenderingDisplaySettingsPage({
    this.settings = const ChatDisplaySettings(),
    this.onChanged,
    super.key,
  });

  final ChatDisplaySettings settings;
  final ValueChanged<ChatDisplaySettings>? onChanged;

  @override
  State<RenderingDisplaySettingsPage> createState() =>
      _RenderingDisplaySettingsPageState();
}

class _RenderingDisplaySettingsPageState
    extends State<RenderingDisplaySettingsPage> {
  late ChatDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant RenderingDisplaySettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '渲染设置',
      actions: <Widget>[
        IconButton(
          key: const Key('rendering_reset_button'),
          tooltip: '恢复默认',
          onPressed: _resetSettings,
          icon: const Icon(Icons.restart_alt, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _RenderingPreviewCard(settings: _settings),
          ),
          SettingsSection(
            title: '文本渲染',
            children: <Widget>[
              SettingsSwitchRow(
                key: const Key('rendering_selectable_text_row'),
                icon: Icons.text_fields,
                title: '消息文本可选择',
                value: _settings.selectableMessageText,
                onChanged: (value) {
                  _update(_settings.copyWith(selectableMessageText: value));
                },
              ),
              SettingsRow(
                key: const Key('rendering_message_font_scale_row'),
                icon: Icons.text_increase,
                title: '聊天字体大小',
                value: _settings.messageFontScaleLabel,
                onTap: () => unawaited(_openMessageFontScale()),
              ),
              SettingsRow(
                key: const Key('rendering_app_font_row'),
                icon: Icons.font_download_outlined,
                title: '应用字体',
                value: _settings.appFont.label,
                onTap: () => unawaited(_openAppFont()),
              ),
              SettingsRow(
                key: const Key('rendering_code_font_row'),
                icon: Icons.code,
                title: '代码字体',
                value: _settings.codeFont.label,
                onTap: () => unawaited(_openCodeFont()),
              ),
            ],
          ),
          SettingsSection(
            title: '背景渲染',
            children: <Widget>[
              SettingsRow(
                key: const Key('rendering_background_mask_row'),
                icon: Icons.image_outlined,
                title: '聊天背景遮罩透明度',
                value: _settings.backgroundMaskOpacityLabel,
                onTap: () => unawaited(_openBackgroundMaskOpacity()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAppFont() {
    return _showChoiceSheet<ChatAppFont>(
      title: '应用字体',
      selected: _settings.appFont,
      items: ChatAppFont.values.map((font) {
        return _ChoiceItem<ChatAppFont>(
          key: 'rendering_app_font_${font.name}',
          label: font.label,
          value: font,
        );
      }).toList(),
      onSelected: (font) {
        _update(_settings.copyWith(appFont: font));
      },
    );
  }

  Future<void> _openCodeFont() {
    return _showChoiceSheet<ChatCodeFont>(
      title: '代码字体',
      selected: _settings.codeFont,
      items: ChatCodeFont.values.map((font) {
        return _ChoiceItem<ChatCodeFont>(
          key: 'rendering_code_font_${font.name}',
          label: font.label,
          value: font,
        );
      }).toList(),
      onSelected: (font) {
        _update(_settings.copyWith(codeFont: font));
      },
    );
  }

  Future<void> _openMessageFontScale() {
    return _showChoiceSheet<double>(
      title: '聊天字体大小',
      selected: _settings.messageFontScale,
      items: const <_ChoiceItem<double>>[
        _ChoiceItem<double>(
          key: 'rendering_message_font_90',
          label: '90%',
          value: 0.90,
        ),
        _ChoiceItem<double>(
          key: 'rendering_message_font_100',
          label: '100%',
          value: 1.0,
        ),
        _ChoiceItem<double>(
          key: 'rendering_message_font_110',
          label: '110%',
          value: 1.1,
        ),
        _ChoiceItem<double>(
          key: 'rendering_message_font_125',
          label: '125%',
          value: 1.25,
        ),
        _ChoiceItem<double>(
          key: 'rendering_message_font_140',
          label: '140%',
          value: 1.4,
        ),
      ],
      onSelected: (scale) {
        _update(_settings.copyWith(messageFontScale: scale));
      },
    );
  }

  Future<void> _openBackgroundMaskOpacity() {
    return _showChoiceSheet<double>(
      title: '聊天背景遮罩透明度',
      selected: _settings.backgroundMaskOpacity,
      items: const <_ChoiceItem<double>>[
        _ChoiceItem<double>(
          key: 'rendering_mask_0',
          label: '0%',
          value: 0.0,
        ),
        _ChoiceItem<double>(
          key: 'rendering_mask_50',
          label: '50%',
          value: 0.5,
        ),
        _ChoiceItem<double>(
          key: 'rendering_mask_75',
          label: '75%',
          value: 0.75,
        ),
        _ChoiceItem<double>(
          key: 'rendering_mask_100',
          label: '100%',
          value: 1.0,
        ),
      ],
      onSelected: (opacity) {
        _update(_settings.copyWith(backgroundMaskOpacity: opacity));
      },
    );
  }

  Future<void> _showChoiceSheet<T>({
    required String title,
    required T selected,
    required List<_ChoiceItem<T>> items,
    required ValueChanged<T> onSelected,
  }) async {
    final next = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ChoiceSheet<T>(
          title: title,
          selected: selected,
          items: items,
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    onSelected(next);
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  void _resetSettings() {
    const defaults = ChatDisplaySettings();
    _update(
      _settings.copyWith(
        selectableMessageText: defaults.selectableMessageText,
        appFont: defaults.appFont,
        codeFont: defaults.codeFont,
        messageFontScale: defaults.messageFontScale,
        backgroundMaskOpacity: defaults.backgroundMaskOpacity,
      ),
    );
  }
}

class BehaviorDisplaySettingsPage extends StatefulWidget {
  const BehaviorDisplaySettingsPage({
    this.settings = const ChatDisplaySettings(),
    this.onChanged,
    super.key,
  });

  final ChatDisplaySettings settings;
  final ValueChanged<ChatDisplaySettings>? onChanged;

  @override
  State<BehaviorDisplaySettingsPage> createState() =>
      _BehaviorDisplaySettingsPageState();
}

class _BehaviorDisplaySettingsPageState
    extends State<BehaviorDisplaySettingsPage> {
  late ChatDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant BehaviorDisplaySettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '行为与启动',
      actions: <Widget>[
        IconButton(
          key: const Key('behavior_reset_button'),
          tooltip: '恢复默认',
          onPressed: _resetSettings,
          icon: const Icon(Icons.restart_alt, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          SettingsSection(
            title: '启动',
            topPadding: 18,
            children: <Widget>[
              SettingsRow(
                key: const Key('behavior_color_mode_row'),
                icon: Icons.dark_mode_outlined,
                title: '颜色模式',
                value: _settings.colorMode.label,
                onTap: () => unawaited(_openColorMode()),
              ),
            ],
          ),
          SettingsSection(
            title: '发送',
            children: <Widget>[
              SettingsSwitchRow(
                key: const Key('behavior_haptic_feedback_row'),
                icon: Icons.vibration_outlined,
                title: '触觉反馈',
                value: _settings.hapticFeedback,
                onChanged: (value) {
                  _update(_settings.copyWith(hapticFeedback: value));
                },
              ),
              SettingsRow(
                key: const Key('behavior_auto_scroll_delay_row'),
                icon: Icons.arrow_downward,
                title: '自动回到底部延迟',
                value: _settings.autoScrollDelayLabel,
                onTap: () => unawaited(_openAutoScrollDelay()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openColorMode() {
    return _showChoiceSheet<ChatColorMode>(
      title: '颜色模式',
      selected: _settings.colorMode,
      items: ChatColorMode.values.map((mode) {
        return _ChoiceItem<ChatColorMode>(
          key: 'behavior_color_mode_${mode.name}',
          label: mode.label,
          value: mode,
        );
      }).toList(),
      onSelected: (mode) {
        _update(_settings.copyWith(colorMode: mode));
      },
    );
  }

  Future<void> _openAutoScrollDelay() {
    return _showChoiceSheet<Duration>(
      title: '自动回到底部延迟',
      selected: _settings.autoScrollDelay,
      items: const <_ChoiceItem<Duration>>[
        _ChoiceItem<Duration>(
          key: 'behavior_auto_scroll_0',
          label: '立即',
          value: Duration.zero,
        ),
        _ChoiceItem<Duration>(
          key: 'behavior_auto_scroll_2',
          label: '2s',
          value: Duration(seconds: 2),
        ),
        _ChoiceItem<Duration>(
          key: 'behavior_auto_scroll_5',
          label: '5s',
          value: Duration(seconds: 5),
        ),
        _ChoiceItem<Duration>(
          key: 'behavior_auto_scroll_8',
          label: '8s',
          value: Duration(seconds: 8),
        ),
        _ChoiceItem<Duration>(
          key: 'behavior_auto_scroll_12',
          label: '12s',
          value: Duration(seconds: 12),
        ),
      ],
      onSelected: (delay) {
        _update(_settings.copyWith(autoScrollDelay: delay));
      },
    );
  }

  Future<void> _showChoiceSheet<T>({
    required String title,
    required T selected,
    required List<_ChoiceItem<T>> items,
    required ValueChanged<T> onSelected,
  }) async {
    final next = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ChoiceSheet<T>(
          title: title,
          selected: selected,
          items: items,
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    onSelected(next);
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  void _resetSettings() {
    const defaults = ChatDisplaySettings();
    _update(
      _settings.copyWith(
        colorMode: defaults.colorMode,
        hapticFeedback: defaults.hapticFeedback,
        autoScrollDelay: defaults.autoScrollDelay,
      ),
    );
  }
}

class ChatItemsDisplaySettingsPage extends StatefulWidget {
  const ChatItemsDisplaySettingsPage({
    this.settings = const ChatDisplaySettings(),
    this.onChanged,
    super.key,
  });

  final ChatDisplaySettings settings;
  final ValueChanged<ChatDisplaySettings>? onChanged;

  @override
  State<ChatItemsDisplaySettingsPage> createState() =>
      _ChatItemsDisplaySettingsPageState();
}

class _ChatItemsDisplaySettingsPageState
    extends State<ChatItemsDisplaySettingsPage> {
  late ChatDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant ChatItemsDisplaySettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '聊天项显示',
      actions: <Widget>[
        IconButton(
          key: const Key('chat_items_reset_button'),
          tooltip: '恢复默认',
          onPressed: _resetSettings,
          icon: const Icon(Icons.restart_alt, size: 30),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _ChatItemsPreviewCard(settings: _settings),
          ),
          SettingsSection(
            title: '显示内容',
            children: <Widget>[
              SettingsSwitchRow(
                key: const Key('chat_items_show_avatar_row'),
                icon: Icons.account_circle_outlined,
                title: '显示头像',
                value: _settings.showMessageAvatars,
                onChanged: (value) {
                  _update(_settings.copyWith(showMessageAvatars: value));
                },
              ),
              SettingsSwitchRow(
                key: const Key('chat_items_show_author_row'),
                icon: Icons.badge_outlined,
                title: '显示名称',
                value: _settings.showMessageAuthorNames,
                onChanged: (value) {
                  _update(_settings.copyWith(showMessageAuthorNames: value));
                },
              ),
              SettingsSwitchRow(
                key: const Key('chat_items_show_time_row'),
                icon: Icons.schedule_outlined,
                title: '显示消息时间',
                value: _settings.showMessageTimestamps,
                onChanged: (value) {
                  _update(_settings.copyWith(showMessageTimestamps: value));
                },
              ),
              SettingsSwitchRow(
                key: const Key('chat_items_show_actions_row'),
                icon: Icons.more_horiz,
                title: '显示操作按钮',
                value: _settings.showMessageActions,
                onChanged: (value) {
                  _update(_settings.copyWith(showMessageActions: value));
                },
              ),
            ],
          ),
          SettingsSection(
            title: '排版与交互',
            children: <Widget>[
              SettingsSwitchRow(
                key: const Key('chat_items_compact_spacing_row'),
                icon: Icons.format_line_spacing,
                title: '紧凑消息间距',
                value: _settings.compactMessageSpacing,
                onChanged: (value) {
                  _update(_settings.copyWith(compactMessageSpacing: value));
                },
              ),
              SettingsSwitchRow(
                key: const Key('chat_items_selectable_text_row'),
                icon: Icons.text_fields,
                title: '消息文本可选择',
                value: _settings.selectableMessageText,
                onChanged: (value) {
                  _update(_settings.copyWith(selectableMessageText: value));
                },
              ),
              SettingsRow(
                key: const Key('chat_items_background_row'),
                icon: Icons.chat_outlined,
                title: '聊天消息背景',
                value: _settings.messageBackground.label,
                onTap: () => unawaited(_openMessageBackground()),
              ),
              SettingsRow(
                key: const Key('chat_items_font_scale_row'),
                icon: Icons.text_increase,
                title: '聊天字体大小',
                value: _settings.messageFontScaleLabel,
                onTap: () => unawaited(_openMessageFontScale()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMessageBackground() {
    return _showChoiceSheet<ChatMessageBackground>(
      title: '聊天消息背景',
      selected: _settings.messageBackground,
      items: ChatMessageBackground.values.map((background) {
        return _ChoiceItem<ChatMessageBackground>(
          key: 'chat_items_background_${background.name}',
          label: background.label,
          value: background,
        );
      }).toList(),
      onSelected: (background) {
        _update(_settings.copyWith(messageBackground: background));
      },
    );
  }

  Future<void> _openMessageFontScale() {
    return _showChoiceSheet<double>(
      title: '聊天字体大小',
      selected: _settings.messageFontScale,
      items: const <_ChoiceItem<double>>[
        _ChoiceItem<double>(
          key: 'chat_items_message_font_90',
          label: '90%',
          value: 0.90,
        ),
        _ChoiceItem<double>(
          key: 'chat_items_message_font_100',
          label: '100%',
          value: 1.0,
        ),
        _ChoiceItem<double>(
          key: 'chat_items_message_font_110',
          label: '110%',
          value: 1.1,
        ),
        _ChoiceItem<double>(
          key: 'chat_items_message_font_125',
          label: '125%',
          value: 1.25,
        ),
        _ChoiceItem<double>(
          key: 'chat_items_message_font_140',
          label: '140%',
          value: 1.4,
        ),
      ],
      onSelected: (scale) {
        _update(_settings.copyWith(messageFontScale: scale));
      },
    );
  }

  Future<void> _showChoiceSheet<T>({
    required String title,
    required T selected,
    required List<_ChoiceItem<T>> items,
    required ValueChanged<T> onSelected,
  }) async {
    final next = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ChoiceSheet<T>(
          title: title,
          selected: selected,
          items: items,
        );
      },
    );

    if (next == null || !mounted) {
      return;
    }

    onSelected(next);
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  void _resetSettings() {
    const defaults = ChatDisplaySettings();
    _update(
      _settings.copyWith(
        showMessageAvatars: defaults.showMessageAvatars,
        showMessageAuthorNames: defaults.showMessageAuthorNames,
        showMessageTimestamps: defaults.showMessageTimestamps,
        showMessageActions: defaults.showMessageActions,
        compactMessageSpacing: defaults.compactMessageSpacing,
        selectableMessageText: defaults.selectableMessageText,
        messageBackground: defaults.messageBackground,
        messageFontScale: defaults.messageFontScale,
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.settings,
  });

  final ChatDisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final previewSettings = settings.copyWith(showMessageActions: false);
    final maskAlpha = settings.backgroundMaskOpacity;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '预览',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: settingsPrimaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _ThemeColorDot(color: colors.primary),
                const SizedBox(width: 8),
                _ThemeColorDot(color: colors.secondary),
                const SizedBox(width: 8),
                _ThemeColorDot(color: colors.surfaceContainerHigh),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  colors.surfaceContainerLow.withValues(alpha: maskAlpha),
                  colors.surfaceContainerHigh.withValues(alpha: 0.32),
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: settingsDividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IgnorePointer(
                  child: MessageBubble(
                    message: ChatMessage(
                      id: 'theme_preview',
                      author: ChatMessageAuthor.assistant,
                      content: '当前主题会同步影响聊天背景和气泡色彩。',
                      createdAt: DateTime(2026, 6, 1, 9, 33),
                    ),
                    displaySettings: previewSettings,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeColorDot extends StatelessWidget {
  const _ThemeColorDot({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: settingsDividerColor),
      ),
      child: const SizedBox.square(dimension: 18),
    );
  }
}

class _RenderingPreviewCard extends StatelessWidget {
  const _RenderingPreviewCard({
    required this.settings,
  });

  final ChatDisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    final previewSettings = settings.copyWith(showMessageActions: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: settingsPrimaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            IgnorePointer(
              child: MessageBubble(
                message: ChatMessage(
                  id: 'rendering_preview',
                  author: ChatMessageAuthor.assistant,
                  content: '普通文本和代码片段会按当前字体渲染。\n\n'
                      '```dart\n'
                      'final ready = true;\n'
                      '```',
                  createdAt: DateTime(2026, 6, 1, 9, 32),
                ),
                displaySettings: previewSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatItemsPreviewCard extends StatelessWidget {
  const _ChatItemsPreviewCard({
    required this.settings,
  });

  final ChatDisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: settingsPrimaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            IgnorePointer(
              child: MessageBubble(
                message: ChatMessage(
                  id: 'preview_assistant',
                  author: ChatMessageAuthor.assistant,
                  content: '我会按当前显示设置呈现消息内容。',
                  createdAt: DateTime(2026, 6, 1, 9, 30),
                ),
                displaySettings: settings,
                onCopy: () {},
              ),
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              child: MessageBubble(
                message: ChatMessage(
                  id: 'preview_user',
                  author: ChatMessageAuthor.user,
                  content: '这是一条用户消息。',
                  createdAt: DateTime(2026, 6, 1, 9, 31),
                ),
                displaySettings: settings,
                onCopy: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplaySettingsCard extends StatelessWidget {
  const _DisplaySettingsCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      widgets.add(children[index]);
      if (index < children.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            color: settingsDividerColor,
            indent: 74,
            endIndent: 20,
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: widgets),
      ),
    );
  }
}

class _DisplaySwitchRow extends StatelessWidget {
  const _DisplaySwitchRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 18, 8),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: 34,
                  child: Icon(icon, size: 30, color: settingsPrimaryText),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: settingsPrimaryText,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Switch(
                  key: switchKey,
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.selected,
    required this.items,
  });

  final String title;
  final T selected;
  final List<_ChoiceItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SheetTitle(title),
            ...items.map((item) {
              return ListTile(
                key: Key(item.key),
                title: Text(item.label),
                trailing:
                    selected == item.value ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(item.value),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ChoiceItem<T> {
  const _ChoiceItem({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final T value;
}
