import 'package:flutter/material.dart';

import 'settings_components.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenFrame(
      title: '显示设置',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: settingsCardBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: <Widget>[
                  SettingsRow(
                    icon: Icons.palette_outlined,
                    title: '主题设置',
                    value: '海雾蓝',
                    onTap: () => _showPending(context, '主题设置'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.translate_outlined,
                    title: '应用语言',
                    value: '跟随系统',
                    onTap: () => _showPending(context, '应用语言'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.chat_bubble_outline,
                    title: '聊天项显示',
                    onTap: () => _showPending(context, '聊天项显示'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.format_color_text_outlined,
                    title: '渲染设置',
                    onTap: () => _showPending(context, '渲染设置'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    title: '行为与启动',
                    onTap: () => _showPending(context, '行为与启动'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.vibration_outlined,
                    title: '触觉反馈',
                    onTap: () => _showPending(context, '触觉反馈'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.chat_outlined,
                    title: '聊天消息背景',
                    value: '默认',
                    onTap: () => _showPending(context, '聊天消息背景'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.text_fields,
                    title: '应用字体',
                    value: '系统默认',
                    onTap: () => _showPending(context, '应用字体'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.code,
                    title: '代码字体',
                    value: '系统默认',
                    onTap: () => _showPending(context, '代码字体'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.text_increase,
                    title: '聊天字体大小',
                    value: '110%',
                    onTap: () => _showPending(context, '聊天字体大小'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.arrow_downward,
                    title: '自动回到底部延迟',
                    value: '8s',
                    onTap: () => _showPending(context, '自动回到底部延迟'),
                  ),
                  const Divider(
                    height: 1,
                    color: settingsDividerColor,
                    indent: 74,
                    endIndent: 20,
                  ),
                  SettingsRow(
                    icon: Icons.image_outlined,
                    title: '背景图片遮罩透明度',
                    value: '100%',
                    onTap: () => _showPending(context, '背景图片遮罩透明度'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPending(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name 暂未接入')),
    );
  }
}
