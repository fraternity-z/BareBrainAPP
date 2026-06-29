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
          icon: const Icon(Icons.restart_alt, size: 24),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          _DisplaySettingsCard(
            children: <Widget>[
              SettingsRow(
                key: const Key('display_theme_preset_row'),
                icon: Icons.palette_outlined,
                title: '主题设置',
                value:
                    '${_settings.colorMode.label} · ${_settings.themePreset.label}',
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
                key: const Key('display_font_row'),
                icon: Icons.text_fields,
                title: '字体',
                value: _fontSummary(),
                onTap: _openFontSettings,
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

  Future<void> _openMessageFontScale() {
    return _showSettingsSliderSheet(
      context: context,
      title: '聊天字体大小',
      value: _settings.messageFontScale * 100,
      min: 90,
      max: 140,
      divisions: 50,
      sliderKey: const Key('message_font_scale_slider'),
      valueLabelBuilder: _formatPercentSliderValue,
      tickLabels: const <_SliderTickLabel>[
        _SliderTickLabel(90, '90%'),
        _SliderTickLabel(100, '100%'),
        _SliderTickLabel(110, '110%'),
        _SliderTickLabel(120, '120%'),
        _SliderTickLabel(130, '130%'),
        _SliderTickLabel(140, '140%'),
      ],
      onChanged: (value) {
        _update(_settings.copyWith(messageFontScale: value / 100));
      },
    );
  }

  Future<void> _openAutoScrollDelay() {
    return _showSettingsSliderSheet(
      context: context,
      title: '自动回到底部延迟',
      value: _settings.autoScrollDelay.inSeconds.toDouble(),
      min: 0,
      max: 60,
      divisions: 60,
      sliderKey: const Key('auto_scroll_delay_slider'),
      subtitle: '用户停止滚动后等待多久再自动回到底部',
      valueLabelBuilder: _formatDelaySliderValue,
      tickLabels: const <_SliderTickLabel>[
        _SliderTickLabel(0, '立即'),
        _SliderTickLabel(15, '15s'),
        _SliderTickLabel(30, '30s'),
        _SliderTickLabel(45, '45s'),
        _SliderTickLabel(60, '60s'),
      ],
      onChanged: (value) {
        _update(
          _settings.copyWith(
            autoScrollDelay: Duration(seconds: value.round()),
          ),
        );
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

  void _openFontSettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => FontDisplaySettingsPage(
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
    final enabledCount = <bool>[
      _settings.inlineMathRendering,
      _settings.mathEquationRendering,
      _settings.userMessageMarkdownRendering,
      _settings.reasoningMarkdownRendering,
      _settings.assistantMessageMarkdownRendering,
      _settings.autoFoldCodeBlocks,
      _settings.mobileCodeBlockAutoWrap,
    ].where((enabled) => enabled).length;

    return '$enabledCount 项启用';
  }

  String _behaviorSummary() {
    final enabledCount = <bool>[
      _settings.foldThinkingSteps,
      _settings.deleteMessagesBelowOnRegenerate,
      _settings.confirmBeforeRegenerate,
      _settings.showMessageNavigationButtons,
      _settings.showConversationListDates,
      _settings.keepDrawerOpenOnConversationSelect,
      _settings.sendMessageWithEnterKey,
    ].where((enabled) => enabled).length;

    return '$enabledCount 项启用';
  }

  String _fontSummary() {
    return '${_settings.appFont.label} · ${_settings.codeFont.label}';
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
          icon: const Icon(Icons.restart_alt, size: 24),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
                key: const Key('theme_color_mode_row'),
                icon: Icons.light_mode_outlined,
                title: '颜色模式',
                value: _settings.colorMode.label,
                onTap: () => unawaited(_openColorMode()),
              ),
              SettingsRow(
                key: const Key('theme_preset_row'),
                icon: Icons.palette_outlined,
                title: '主题预设',
                value: _settings.themePreset.label,
                onTap: () => unawaited(_openThemePreset()),
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
      ),
    );
  }
}

class FontDisplaySettingsPage extends StatefulWidget {
  const FontDisplaySettingsPage({
    this.settings = const ChatDisplaySettings(),
    this.onChanged,
    super.key,
  });

  final ChatDisplaySettings settings;
  final ValueChanged<ChatDisplaySettings>? onChanged;

  @override
  State<FontDisplaySettingsPage> createState() =>
      _FontDisplaySettingsPageState();
}

class _FontDisplaySettingsPageState extends State<FontDisplaySettingsPage> {
  late ChatDisplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  void didUpdateWidget(covariant FontDisplaySettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '字体',
      actions: <Widget>[
        IconButton(
          key: const Key('font_reset_button'),
          tooltip: '恢复默认',
          onPressed: _resetSettings,
          icon: const Icon(Icons.restart_alt, size: 24),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          SettingsSection(
            title: '字体',
            topPadding: 18,
            children: <Widget>[
              SettingsRow(
                key: const Key('font_app_font_row'),
                icon: Icons.text_fields,
                title: '应用字体',
                value: _settings.appFont.label,
                onTap: () => unawaited(_openAppFont()),
              ),
              SettingsRow(
                key: const Key('font_code_font_row'),
                icon: Icons.code,
                title: '代码字体',
                value: _settings.codeFont.label,
                onTap: () => unawaited(_openCodeFont()),
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
        appFont: defaults.appFont,
        codeFont: defaults.codeFont,
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
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        children: <Widget>[
          _RenderingSettingsCard(
            children: <Widget>[
              _RenderingSwitchRow(
                key: const Key('rendering_inline_math_row'),
                switchKey: const Key('rendering_inline_math_switch'),
                icon: const _RenderingTextIcon('#'),
                title: '启用 \$...\$ 渲染',
                value: _settings.inlineMathRendering,
                onChanged: (value) {
                  _update(_settings.copyWith(inlineMathRendering: value));
                },
              ),
              _RenderingSwitchRow(
                key: const Key('rendering_math_equation_row'),
                switchKey: const Key('rendering_math_equation_switch'),
                icon: const _RenderingTextIcon('<>'),
                title: '启用数学公式渲染',
                value: _settings.mathEquationRendering,
                onChanged: (value) {
                  _update(_settings.copyWith(mathEquationRendering: value));
                },
              ),
              _RenderingSwitchRow(
                key: const Key('rendering_user_markdown_row'),
                switchKey: const Key('rendering_user_markdown_switch'),
                icon: const Icon(Icons.text_fields, size: 24),
                title: '用户消息 Markdown 渲染',
                value: _settings.userMessageMarkdownRendering,
                onChanged: (value) {
                  _update(
                    _settings.copyWith(
                      userMessageMarkdownRendering: value,
                    ),
                  );
                },
              ),
              _RenderingSwitchRow(
                key: const Key('rendering_reasoning_markdown_row'),
                switchKey: const Key('rendering_reasoning_markdown_switch'),
                icon: const Icon(Icons.psychology_outlined, size: 25),
                title: '思维链 Markdown 渲染',
                value: _settings.reasoningMarkdownRendering,
                onChanged: (value) {
                  _update(
                    _settings.copyWith(reasoningMarkdownRendering: value),
                  );
                },
              ),
              _RenderingSwitchRow(
                key: const Key('rendering_assistant_markdown_row'),
                switchKey: const Key('rendering_assistant_markdown_switch'),
                icon: const Icon(Icons.chat_bubble_outline, size: 24),
                title: '助手消息 Markdown 渲染',
                value: _settings.assistantMessageMarkdownRendering,
                onChanged: (value) {
                  _update(
                    _settings.copyWith(
                      assistantMessageMarkdownRendering: value,
                    ),
                  );
                },
              ),
              _RenderingSwitchRow(
                key: const Key('rendering_auto_fold_code_row'),
                switchKey: const Key('rendering_auto_fold_code_switch'),
                icon: const Icon(Icons.unfold_less, size: 25),
                title: '自动折叠代码块',
                value: _settings.autoFoldCodeBlocks,
                onChanged: (value) {
                  _update(_settings.copyWith(autoFoldCodeBlocks: value));
                },
              ),
              _RenderingSwitchRow(
                key: const Key('rendering_mobile_code_wrap_row'),
                switchKey: const Key('rendering_mobile_code_wrap_switch'),
                icon: const Icon(Icons.wrap_text, size: 25),
                title: '移动端代码块自动换行',
                value: _settings.mobileCodeBlockAutoWrap,
                onChanged: (value) {
                  _update(_settings.copyWith(mobileCodeBlockAutoWrap: value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
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
          icon: const Icon(Icons.restart_alt, size: 24),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        children: <Widget>[
          _RenderingSettingsCard(
            children: <Widget>[
              _RenderingSwitchRow(
                key: const Key('behavior_fold_thinking_steps_row'),
                switchKey: const Key('behavior_fold_thinking_steps_switch'),
                icon: const Icon(Icons.account_tree_outlined, size: 25),
                title: '折叠思考步骤',
                value: _settings.foldThinkingSteps,
                onChanged: (value) {
                  _update(_settings.copyWith(foldThinkingSteps: value));
                },
              ),
              _RenderingSwitchRow(
                key: const Key('behavior_delete_below_regenerate_row'),
                switchKey: const Key('behavior_delete_below_regenerate_switch'),
                icon: const Icon(Icons.refresh, size: 25),
                title: '重新生成时删除下面的消息',
                value: _settings.deleteMessagesBelowOnRegenerate,
                onChanged: (value) {
                  _update(
                    _settings.copyWith(
                      deleteMessagesBelowOnRegenerate: value,
                    ),
                  );
                },
              ),
              _RenderingSwitchRow(
                key: const Key('behavior_confirm_regenerate_row'),
                switchKey: const Key('behavior_confirm_regenerate_switch'),
                icon: const Icon(Icons.chat_bubble_outline, size: 25),
                title: '重新生成前弹出确认',
                value: _settings.confirmBeforeRegenerate,
                onChanged: (value) {
                  _update(_settings.copyWith(confirmBeforeRegenerate: value));
                },
              ),
              _RenderingSwitchRow(
                key: const Key('behavior_message_navigation_row'),
                switchKey: const Key('behavior_message_navigation_switch'),
                icon: const Icon(Icons.chevron_right, size: 26),
                title: '消息导航按钮',
                value: _settings.showMessageNavigationButtons,
                onChanged: (value) {
                  _update(
                    _settings.copyWith(showMessageNavigationButtons: value),
                  );
                },
              ),
              _RenderingSwitchRow(
                key: const Key('behavior_conversation_dates_row'),
                switchKey: const Key('behavior_conversation_dates_switch'),
                icon: const Icon(Icons.calendar_today_outlined, size: 24),
                title: '显示对话列表日期',
                value: _settings.showConversationListDates,
                onChanged: (value) {
                  _update(_settings.copyWith(showConversationListDates: value));
                },
              ),
              _RenderingSwitchRow(
                key: const Key('behavior_keep_drawer_open_row'),
                switchKey: const Key('behavior_keep_drawer_open_switch'),
                icon: const Icon(Icons.view_sidebar_outlined, size: 25),
                title: '点选话题时不自动关闭侧边栏',
                value: _settings.keepDrawerOpenOnConversationSelect,
                onChanged: (value) {
                  _update(
                    _settings.copyWith(
                      keepDrawerOpenOnConversationSelect: value,
                    ),
                  );
                },
              ),
              _RenderingSwitchRow(
                key: const Key('behavior_enter_to_send_row'),
                switchKey: const Key('behavior_enter_to_send_switch'),
                icon: const Icon(Icons.keyboard_return, size: 25),
                title: '回车键发送消息',
                value: _settings.sendMessageWithEnterKey,
                onChanged: (value) {
                  _update(_settings.copyWith(sendMessageWithEnterKey: value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
  }

  void _resetSettings() {
    const defaults = ChatDisplaySettings();
    _update(
      _settings.copyWith(
        foldThinkingSteps: defaults.foldThinkingSteps,
        deleteMessagesBelowOnRegenerate:
            defaults.deleteMessagesBelowOnRegenerate,
        confirmBeforeRegenerate: defaults.confirmBeforeRegenerate,
        showMessageNavigationButtons: defaults.showMessageNavigationButtons,
        showConversationListDates: defaults.showConversationListDates,
        keepDrawerOpenOnConversationSelect:
            defaults.keepDrawerOpenOnConversationSelect,
        sendMessageWithEnterKey: defaults.sendMessageWithEnterKey,
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
          icon: const Icon(Icons.restart_alt, size: 24),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
    return _showSettingsSliderSheet(
      context: context,
      title: '聊天字体大小',
      value: _settings.messageFontScale * 100,
      min: 90,
      max: 140,
      divisions: 50,
      sliderKey: const Key('chat_items_message_font_scale_slider'),
      valueLabelBuilder: _formatPercentSliderValue,
      tickLabels: const <_SliderTickLabel>[
        _SliderTickLabel(90, '90%'),
        _SliderTickLabel(100, '100%'),
        _SliderTickLabel(110, '110%'),
        _SliderTickLabel(120, '120%'),
        _SliderTickLabel(130, '130%'),
        _SliderTickLabel(140, '140%'),
      ],
      onChanged: (value) {
        _update(_settings.copyWith(messageFontScale: value / 100));
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
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
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
                          color: settingsPrimaryTextColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
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
                  colors.surfaceContainerLow,
                  colors.surfaceContainerHigh.withValues(alpha: 0.32),
                ),
                borderRadius: BorderRadius.circular(settingsCardRadius),
                border: Border.all(color: settingsDividerColorFor(context)),
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
        border: Border.all(color: settingsDividerColorFor(context)),
      ),
      child: const SizedBox.square(dimension: 18),
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
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: settingsPrimaryTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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

class _RenderingSettingsCard extends StatelessWidget {
  const _RenderingSettingsCard({
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
          Divider(
            height: 1,
            color: settingsDividerColorFor(context),
            indent: 63,
            endIndent: 14,
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(settingsCardRadius),
        child: Column(children: widgets),
      ),
    );
  }
}

class _RenderingSwitchRow extends StatelessWidget {
  const _RenderingSwitchRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Key switchKey;
  final Widget icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = settingsPrimaryTextColor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 12, 6),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: 26,
                  child: IconTheme(
                    data: IconThemeData(color: primary),
                    child: Center(child: icon),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  key: switchKey,
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  thumbColor: const WidgetStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xff4665a0);
                    }

                    return const Color(0xffe6e6e8);
                  }),
                  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xff4665a0);
                    }

                    return const Color(0xffd6d6d9);
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenderingTextIcon extends StatelessWidget {
  const _RenderingTextIcon(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: settingsPrimaryTextColor(context),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1,
        letterSpacing: 0,
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
          Divider(
            height: 1,
            color: settingsDividerColorFor(context),
            indent: 74,
            endIndent: 18,
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(settingsCardRadius),
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
    final primary = settingsPrimaryTextColor(context);
    final divider = settingsDividerColorFor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: settingsPageBackgroundColor(context),
                    borderRadius: BorderRadius.circular(settingsCardRadius),
                    border: Border.all(color: divider),
                  ),
                  child: SizedBox.square(
                    dimension: 42,
                    child: Icon(icon, size: 23, color: primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
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

Future<void> _showSettingsSliderSheet({
  required BuildContext context,
  required String title,
  required double value,
  required double min,
  required double max,
  required int divisions,
  required Key sliderKey,
  required String Function(double value) valueLabelBuilder,
  required List<_SliderTickLabel> tickLabels,
  required ValueChanged<double> onChanged,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return _SettingsSliderSheet(
        title: title,
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        sliderKey: sliderKey,
        subtitle: subtitle,
        valueLabelBuilder: valueLabelBuilder,
        tickLabels: tickLabels,
        onChanged: onChanged,
      );
    },
  );
}

String _formatPercentSliderValue(double value) {
  return '${value.round()}%';
}

String _formatDelaySliderValue(double value) {
  final seconds = value.round();
  if (seconds == 0) {
    return '立即';
  }

  return '${seconds}s';
}

class _SettingsSliderSheet extends StatefulWidget {
  const _SettingsSliderSheet({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.sliderKey,
    required this.valueLabelBuilder,
    required this.tickLabels,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Key sliderKey;
  final String? subtitle;
  final String Function(double value) valueLabelBuilder;
  final List<_SliderTickLabel> tickLabels;
  final ValueChanged<double> onChanged;

  @override
  State<_SettingsSliderSheet> createState() => _SettingsSliderSheetState();
}

class _SettingsSliderSheetState extends State<_SettingsSliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _clampValue(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = settingsPrimaryTextColor(context);
    final secondary = settingsSecondaryTextColor(context);
    const activeColor = Color(0xff4665a0);
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff3a3a40)
        : const Color(0xffd6d6dc);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.valueLabelBuilder(_value),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                inactiveTrackColor: inactiveColor,
                activeTickMarkColor: Colors.transparent,
                inactiveTickMarkColor: Colors.transparent,
                overlayColor: activeColor.withValues(alpha: 0.14),
                thumbColor: activeColor,
                trackHeight: 7,
                valueIndicatorColor: activeColor,
                valueIndicatorTextStyle:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
              ),
              child: Slider(
                key: widget.sliderKey,
                value: _value,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                label: widget.valueLabelBuilder(_value),
                onChanged: _handleChanged,
              ),
            ),
            _SliderTickScale(
              labels: widget.tickLabels,
              min: widget.min,
              max: widget.max,
              textColor: secondary,
            ),
            if (widget.subtitle != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleChanged(double value) {
    final next = _clampValue(value);
    setState(() => _value = next);
    widget.onChanged(next);
  }

  double _clampValue(double value) {
    return value.clamp(widget.min, widget.max).toDouble();
  }
}

class _SliderTickScale extends StatelessWidget {
  const _SliderTickScale({
    required this.labels,
    required this.min,
    required this.max,
    required this.textColor,
  });

  final List<_SliderTickLabel> labels;
  final double min;
  final double max;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const labelWidth = 58.0;
          final width = constraints.maxWidth;
          final maxLabelLeft = width > labelWidth ? width - labelWidth : 0.0;
          final maxTickLeft = width > 1 ? width - 1 : 0.0;
          return SizedBox(
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                ...labels.map((label) {
                  final left = _positionFor(label.value, width)
                      .clamp(0.0, maxTickLeft)
                      .toDouble();
                  return Positioned(
                    left: left,
                    top: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.4),
                      ),
                      child: const SizedBox(width: 1, height: 10),
                    ),
                  );
                }),
                ...labels.map((label) {
                  final left =
                      (_positionFor(label.value, width) - labelWidth / 2)
                          .clamp(0.0, maxLabelLeft)
                          .toDouble();
                  return Positioned(
                    left: left,
                    top: 16,
                    width: labelWidth,
                    child: Text(
                      label.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  double _positionFor(double value, double width) {
    if (max == min) {
      return 0;
    }

    final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
    return ratio * width;
  }
}

class _SliderTickLabel {
  const _SliderTickLabel(this.value, this.label);

  final double value;
  final String label;
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
    final primary = settingsPrimaryTextColor(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SheetTitle(title),
            ...items.map((item) {
              final selectedItem = selected == item.value;
              return ListTile(
                key: Key(item.key),
                selected: selectedItem,
                selectedColor: primary,
                title: Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: primary,
                        fontWeight:
                            selectedItem ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                ),
                trailing: selectedItem
                    ? Icon(Icons.check, color: primary, size: 22)
                    : null,
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
              color: settingsPrimaryTextColor(context),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
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
