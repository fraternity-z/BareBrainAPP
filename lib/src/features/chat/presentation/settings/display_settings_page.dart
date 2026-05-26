import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/chat_display_settings.dart';
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
                onTap: () => unawaited(_openThemePreset()),
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
                value: _settings.selectableMessageText ? '可选择文本' : '普通文本',
                onTap: _openRenderingSettings,
              ),
              SettingsRow(
                key: const Key('display_behavior_row'),
                icon: Icons.dark_mode_outlined,
                title: '行为与启动',
                value: _settings.colorMode.label,
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

  Future<void> _openThemePreset() {
    return _showChoiceSheet<ChatThemePreset>(
      title: '主题设置',
      selected: _settings.themePreset,
      items: ChatThemePreset.values.map((preset) {
        return _ChoiceItem<ChatThemePreset>(
          key: 'theme_${preset.name}',
          label: preset.label,
          value: preset,
        );
      }).toList(),
      onSelected: (preset) {
        _update(_settings.copyWith(themePreset: preset));
      },
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

  void _openChatItemSettings() {
    _showSwitchSheet(
      title: '聊天项显示',
      switches: <_SwitchItem>[
        _SwitchItem(
          key: 'show_timestamps',
          label: '显示消息时间',
          value: _settings.showMessageTimestamps,
          onChanged: (value) {
            _update(_settings.copyWith(showMessageTimestamps: value));
          },
        ),
        _SwitchItem(
          key: 'show_actions',
          label: '显示复制操作',
          value: _settings.showMessageActions,
          onChanged: (value) {
            _update(_settings.copyWith(showMessageActions: value));
          },
        ),
        _SwitchItem(
          key: 'compact_spacing',
          label: '紧凑消息间距',
          value: _settings.compactMessageSpacing,
          onChanged: (value) {
            _update(_settings.copyWith(compactMessageSpacing: value));
          },
        ),
      ],
    );
  }

  void _openRenderingSettings() {
    _showSwitchSheet(
      title: '渲染设置',
      switches: <_SwitchItem>[
        _SwitchItem(
          key: 'selectable_text',
          label: '消息文本可选择',
          value: _settings.selectableMessageText,
          onChanged: (value) {
            _update(_settings.copyWith(selectableMessageText: value));
          },
        ),
      ],
    );
  }

  void _openBehaviorSettings() {
    _showSwitchSheet(
      title: '行为与启动',
      switches: <_SwitchItem>[
        _SwitchItem(
          key: 'behavior_haptic',
          label: '发送触觉反馈',
          value: _settings.hapticFeedback,
          onChanged: (value) {
            _update(_settings.copyWith(hapticFeedback: value));
          },
        ),
      ],
      extraChildren: <Widget>[
        const Divider(height: 1),
        ...ChatColorMode.values.map((mode) {
          return ListTile(
            key: Key('display_color_mode_${mode.name}'),
            title: Text(mode.label),
            trailing:
                _settings.colorMode == mode ? const Icon(Icons.check) : null,
            onTap: () {
              _update(_settings.copyWith(colorMode: mode));
              Navigator.of(context).maybePop();
            },
          );
        }),
      ],
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

  void _showSwitchSheet({
    required String title,
    required List<_SwitchItem> switches,
    List<Widget> extraChildren = const <Widget>[],
  }) {
    final switchValues = <String, bool>{
      for (final item in switches) item.key: item.value,
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SheetTitle(title),
                    ...switches.map((item) {
                      return SwitchListTile(
                        key: Key('display_switch_${item.key}'),
                        title: Text(item.label),
                        value: switchValues[item.key] ?? false,
                        onChanged: (value) {
                          setSheetState(() {
                            switchValues[item.key] = value;
                          });
                          item.onChanged(value);
                        },
                      );
                    }),
                    ...extraChildren,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _chatItemsSummary() {
    final time = _settings.showMessageTimestamps ? '时间' : '无时间';
    final action = _settings.showMessageActions ? '操作' : '无操作';
    return '$time · $action';
  }

  void _update(ChatDisplaySettings settings) {
    setState(() => _settings = settings);
    widget.onChanged?.call(settings);
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

class _SwitchItem {
  const _SwitchItem({
    required this.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String key;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
}
