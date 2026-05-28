import 'dart:convert';

import 'package:bare_brain_app/src/features/chat/data/models/chat_app_settings_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_app_settings_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_display_settings_store.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_app_settings_controller.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_display_settings_controller.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/chat_storage_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/data_backup_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/display_settings_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/network_proxy_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/prompt_injection_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/quick_phrases_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/settings_components.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/settings_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/voice_service_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/world_book_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatSettingsPage', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    testWidgets('renders grouped settings in the screenshot style',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
          ),
        ),
      );

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('通用设置'), findsOneWidget);
      expect(find.text('模型与服务'), findsOneWidget);
      expect(find.text('设备连接'), findsOneWidget);
      expect(find.text('颜色模式'), findsOneWidget);
      expect(find.text('助手'), findsNothing);
      expect(find.text('默认模型'), findsNothing);
      expect(find.text('供应商'), findsNothing);
      expect(find.text('搜索服务'), findsNothing);
      expect(find.text('MCP'), findsNothing);
      expect(find.text('连接参数'), findsOneWidget);
    });

    testWidgets('updates color mode from the general settings row',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedDisplaySettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            onDisplaySettingsChanged: (settings) {
              changedDisplaySettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('settings_row_color_mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('color_mode_dark')));
      await tester.pumpAndSettle();

      expect(changedDisplaySettings, isNotNull);
      expect(changedDisplaySettings!.colorMode, ChatColorMode.dark);
      expect(find.text('深色'), findsOneWidget);
    });

    testWidgets('opens display settings and propagates changes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedDisplaySettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            onDisplaySettingsChanged: (settings) {
              changedDisplaySettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('settings_row_display')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('display_theme_preset_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme_graphite')));
      await tester.pumpAndSettle();

      expect(changedDisplaySettings, isNotNull);
      expect(changedDisplaySettings!.themePreset, ChatThemePreset.graphite);
      expect(find.text('岩灰'), findsOneWidget);
    });

    testWidgets('saves connection parameters from the connection sheet',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatConnectionSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_row_connection')),
        300,
      );
      await tester.tap(find.byKey(const Key('settings_row_connection')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('connection_host_field')),
        '10.0.0.2',
      );
      await tester
          .tap(find.byKey(const Key('save_connection_settings_button')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.host, '10.0.0.2');
      expect(changedSettings!.otaSettings.channel, 'stable');
      expect(find.text('ws://10.0.0.2:18789/'), findsOneWidget);
    });

    testWidgets('saves OTA parameters from the OTA sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatConnectionSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_row_ota')),
        300,
      );
      await tester.tap(find.byKey(const Key('settings_row_ota')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('ota_channel_field')), 'beta');
      await tester.tap(find.text('自动检查更新'));
      await tester.tap(find.byKey(const Key('save_ota_settings_button')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.otaSettings.channel, 'beta');
      expect(changedSettings!.otaSettings.autoCheck, isTrue);
      expect(find.text('beta · 自动'), findsOneWidget);
    });

    testWidgets('tests OTA version endpoint from the OTA sheet',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatConnectionSettings? testedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            onTestOtaVersionCheck: (settings) async {
              testedSettings = settings;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_row_ota')),
        300,
      );
      await tester.tap(find.byKey(const Key('settings_row_ota')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('ota_version_path_field')),
        '/api/ota/version',
      );
      await tester.enterText(
        find.byKey(const Key('ota_channel_field')),
        'beta',
      );
      await tester.tap(find.byKey(const Key('test_ota_version_button')));
      await tester.pumpAndSettle();

      expect(testedSettings, isNotNull);
      expect(testedSettings!.host, settings.host);
      expect(testedSettings!.otaSettings.versionPath, '/api/ota/version');
      expect(testedSettings!.otaSettings.channel, 'beta');
      expect(find.text('OTA 版本检查成功'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('ota_channel_field')),
        'stable',
      );
      await tester.pump();

      expect(find.text('OTA 版本检查成功'), findsNothing);
    });

    testWidgets('opens the network proxy page from the settings row',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_row_network_proxy')),
        300,
      );
      await tester.tap(find.byKey(const Key('settings_row_network_proxy')));
      await tester.pumpAndSettle();

      expect(find.text('网络代理'), findsOneWidget);
      expect(find.text('启动代理'), findsOneWidget);
      expect(find.text('代理类型'), findsOneWidget);
      expect(find.text('连接测试'), findsOneWidget);
      expect(find.textContaining('OTA 版本检查'), findsOneWidget);
      expect(find.byKey(const Key('proxy_test_button')), findsOneWidget);
    });

    testWidgets('opens every settings feature row without pending placeholders',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final appSettingsController = ChatAppSettingsController();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            appSettingsController: appSettingsController,
          ),
        ),
      );

      final rows = <Key, String>{
        const Key('settings_row_voice_service'): '语音服务',
        const Key('settings_row_world_book'): '世界书',
        const Key('settings_row_prompt_injection'): '指令注入',
        const Key('settings_row_data_backup'): '数据备份',
        const Key('settings_row_chat_storage'): '聊天记录存储',
      };

      for (final entry in rows.entries) {
        final row = find.byKey(entry.key);
        await tester.scrollUntilVisible(row, 300);
        await tester.tap(row);
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.textContaining('暂未接入'), findsNothing);

        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
      }

      appSettingsController.dispose();
    });

    testWidgets('summarizes persisted app settings on the root settings page',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final appSettingsController = ChatAppSettingsController(
        initialSettings: const ChatAppSettings(
          voice: ChatVoiceSettings(enabled: true),
          quickPhrases: <ChatQuickPhrase>[
            ChatQuickPhrase(
              id: 'phrase-1',
              title: '开场白',
              content: '你好',
            ),
          ],
          networkProxy: ChatNetworkProxySettings(enabled: true),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            appSettingsController: appSettingsController,
          ),
        ),
      );

      expect(find.text('HTTP 服务'), findsOneWidget);
      expect(find.text('1 条'), findsOneWidget);
      expect(find.text('HTTP 127.0.0.1:8080'), findsOneWidget);

      appSettingsController.dispose();
    });

    testWidgets('shows app settings persistence errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final appSettingsController = ChatAppSettingsController(
        store: _FailingAppSettingsStore(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            appSettingsController: appSettingsController,
          ),
        ),
      );

      appSettingsController.updateQuickPhrases(
        const <ChatQuickPhrase>[
          ChatQuickPhrase(
            id: 'phrase-1',
            title: '开场白',
            content: '你好',
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('保存应用设置失败'), findsOneWidget);

      appSettingsController.dispose();
    });

    testWidgets('shows display settings persistence errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            displaySettingsError: '保存显示设置失败：disk full',
          ),
        ),
      );

      expect(find.text('保存显示设置失败：disk full'), findsOneWidget);
    });

    testWidgets('listens for display settings persistence errors',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final displaySettingsController = ChatDisplaySettingsController(
        store: _FailingDisplaySettingsStore(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (_) {},
            displaySettingsController: displaySettingsController,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('settings_row_color_mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('color_mode_dark')));
      await tester.pumpAndSettle();

      expect(find.textContaining('保存显示设置失败'), findsOneWidget);
      expect(find.text('深色'), findsOneWidget);

      displaySettingsController.dispose();
    });

    testWidgets(
        'imports a backup from the root settings page and refreshes rows',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final appSettingsController = ChatAppSettingsController();
      ChatConnectionSettings? changedConnectionSettings;
      ChatDisplaySettings? changedDisplaySettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatSettingsPage(
            settings: settings,
            onSettingsChanged: (settings) {
              changedConnectionSettings = settings;
            },
            onDisplaySettingsChanged: (settings) {
              changedDisplaySettings = settings;
            },
            appSettingsController: appSettingsController,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_row_data_backup')),
        300,
      );
      await tester.tap(find.byKey(const Key('settings_row_data_backup')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '''
{
  "version": 1,
  "appSettings": {
    "version": 1,
    "voice": {"enabled": true, "provider": "custom"},
    "quickPhrases": [
      {"id": "phrase-1", "title": "开场白", "content": "你好", "enabled": true}
    ],
    "networkProxy": {"enabled": true, "server": "proxy.local", "port": 1080},
    "storage": {"retentionPolicy": "thirtyDays"}
  },
  "connectionSettings": {
    "host": "10.0.0.2",
    "port": 18789,
    "clientId": "mobile",
    "secure": false,
    "responseTimeoutMs": 10000
  },
  "displaySettings": {
    "colorMode": "dark"
  }
}
''',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pumpAndSettle();

      expect(find.text('设置备份已导入'), findsOneWidget);

      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();

      expect(changedConnectionSettings, isNotNull);
      expect(changedConnectionSettings!.host, '10.0.0.2');
      expect(changedDisplaySettings, isNotNull);
      expect(changedDisplaySettings!.colorMode, ChatColorMode.dark);
      expect(find.text('深色'), findsOneWidget);
      expect(find.text('HTTP 服务'), findsOneWidget);
      expect(find.text('1 条'), findsOneWidget);
      expect(find.text('HTTP proxy.local:1080'), findsOneWidget);
      expect(find.text('30 天'), findsOneWidget);
      expect(find.text('ws://10.0.0.2:18789/'), findsOneWidget);

      appSettingsController.dispose();
    });
  });

  group('DisplaySettingsPage', () {
    testWidgets('pins value labels next to the trailing chevron',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: DisplaySettingsPage()),
      );

      final firstRow = find.byType(SettingsRow).first;
      final rowRight = tester.getTopRight(firstRow).dx;
      final valueRight = tester.getTopRight(find.text('海雾蓝')).dx;
      final titleRight = tester.getTopRight(find.text('主题设置')).dx;
      final valueLeft = tester.getTopLeft(find.text('海雾蓝')).dx;

      expect(rowRight - valueRight, lessThanOrEqualTo(76));
      expect(valueLeft, greaterThan(titleRight));
      expect(find.text('应用语言'), findsNothing);
    });

    testWidgets('updates choice rows and reports new settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('display_message_font_scale_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('message_font_125')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.messageFontScale, 1.25);
      expect(find.text('125%'), findsOneWidget);
    });

    testWidgets('updates message background and font choices', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('display_message_background_row')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('display_message_background_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('message_background_soft')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.messageBackground, ChatMessageBackground.soft);
      expect(find.text('柔和'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('display_app_font_row')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('display_app_font_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app_font_sans')));
      await tester.pumpAndSettle();

      expect(changedSettings!.appFont, ChatAppFont.sans);
      expect(find.text('屏显黑体'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('display_code_font_row')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('display_code_font_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('code_font_mono')));
      await tester.pumpAndSettle();

      expect(changedSettings!.codeFont, ChatCodeFont.mono);
      expect(find.text('等宽'), findsOneWidget);
    });

    testWidgets('toggles chat item display switches', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('display_chat_items_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('display_switch_show_timestamps')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('display_switch_show_actions')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('display_switch_compact_spacing')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.showMessageTimestamps, isFalse);
      expect(changedSettings!.showMessageActions, isFalse);
      expect(changedSettings!.compactMessageSpacing, isTrue);
    });

    testWidgets('toggles rendering switches', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('display_rendering_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('display_switch_selectable_text')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.selectableMessageText, isFalse);
    });

    testWidgets('toggles haptic feedback from the display row', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('display_haptic_feedback_row')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.hapticFeedback, isFalse);
    });

    testWidgets('updates behavior color mode from the display page',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('display_behavior_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('display_color_mode_dark')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.colorMode, ChatColorMode.dark);
      expect(find.text('深色'), findsOneWidget);
    });

    testWidgets('updates auto scroll delay and background mask',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatDisplaySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DisplaySettingsPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('display_auto_scroll_delay_row')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('display_auto_scroll_delay_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('auto_scroll_2')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.autoScrollDelay, const Duration(seconds: 2));

      await tester.scrollUntilVisible(
        find.byKey(const Key('display_background_mask_row')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('display_background_mask_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mask_50')));
      await tester.pumpAndSettle();

      expect(changedSettings!.backgroundMaskOpacity, 0.5);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('NetworkProxyPage', () {
    testWidgets('renders proxy form defaults in the screenshot layout',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: NetworkProxyPage()),
      );

      expect(find.text('网络代理'), findsOneWidget);
      expect(find.text('启动代理'), findsOneWidget);
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.widgetWithText(TextField, '8080'), findsOneWidget);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('代理绕过'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('proxy_test_url_field')),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('toggles proxy and validates test URL', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: NetworkProxyPage()),
      );

      await tester.tap(find.byKey(const Key('proxy_enabled_switch')));
      await tester.pump();

      final enabledSwitch = tester.widget<Switch>(
        find.byKey(const Key('proxy_enabled_switch')),
      );
      expect(enabledSwitch.value, isTrue);

      expect(find.text('HTTP'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('proxy_test_url_field')),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.enterText(
        find.byKey(const Key('proxy_test_url_field')),
        'not a url',
      );
      await tester.tap(find.byKey(const Key('proxy_test_button')));
      await tester.pump();

      expect(find.text('测试地址必须是 http 或 https URL'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('proxy_test_url_field')),
        'https://example.com',
      );
      await tester.tap(find.byKey(const Key('proxy_test_button')));
      await tester.pump();

      expect(find.text('配置检查通过：HTTP 127.0.0.1:8080'), findsOneWidget);
    });

    testWidgets('saves proxy settings to the caller', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatNetworkProxySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkProxyPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('proxy_enabled_switch')));
      await tester.enterText(
        find.byKey(const Key('proxy_server_field')),
        'proxy.local',
      );
      await tester.enterText(
        find.byKey(const Key('proxy_port_field')),
        '1080',
      );
      await tester.tap(find.byKey(const Key('network_proxy_save_button')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.enabled, isTrue);
      expect(changedSettings!.server, 'proxy.local');
      expect(changedSettings!.port, 1080);
      expect(find.text('网络代理设置已保存'), findsOneWidget);
    });

    testWidgets('saves direct mode while proxy fields are invalid',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatNetworkProxySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkProxyPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('proxy_server_field')),
        'http://proxy.local',
      );
      await tester.enterText(find.byKey(const Key('proxy_port_field')), '0');
      await tester.tap(find.byKey(const Key('network_proxy_save_button')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.enabled, isFalse);
      expect(changedSettings!.server, '127.0.0.1');
      expect(changedSettings!.port, 8080);
      expect(find.text('网络代理设置已保存'), findsOneWidget);
    });

    testWidgets('saves with default test URL when test URL is invalid',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatNetworkProxySettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkProxyPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('proxy_test_url_field')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('proxy_test_url_field')),
        'not a url',
      );
      await tester.tap(find.byKey(const Key('network_proxy_save_button')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.testUrl, 'https://example.com');
      expect(find.text('https://example.com'), findsOneWidget);
      expect(find.text('网络代理设置已保存'), findsOneWidget);
    });

    testWidgets('runs injected proxy connection test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      ChatNetworkProxySettings? testedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: NetworkProxyPage(
            onTestConnection: (settings) async {
              testedSettings = settings;
            },
          ),
        ),
      );

      await tester.drag(find.byType(Scrollable).last, const Offset(0, -520));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('proxy_test_url_field')).last,
        'https://example.com',
      );
      await tester.tap(find.byKey(const Key('proxy_test_button')));
      await tester.pumpAndSettle();

      expect(testedSettings, isNotNull);
      expect(testedSettings!.testUrl, 'https://example.com');
      expect(find.text('连接测试成功：当前为直连模式'), findsOneWidget);
    });
  });

  group('VoiceServicePage', () {
    testWidgets('saves voice service settings', (tester) async {
      ChatVoiceSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceServicePage(
            settings: const ChatVoiceSettings(
              enabled: true,
              provider: ChatVoiceProvider.custom,
            ),
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('voice_endpoint_field')),
        'https://voice.example.com',
      );
      await tester.enterText(
        find.byKey(const Key('voice_speaker_field')),
        'alice',
      );
      await tester.tap(find.byKey(const Key('voice_service_save_button')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.endpoint, 'https://voice.example.com');
      expect(changedSettings!.speaker, 'alice');
      expect(find.text('语音服务设置已保存'), findsOneWidget);
    });

    testWidgets('saves disabled voice service while fields are invalid',
        (tester) async {
      ChatVoiceSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceServicePage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('voice_endpoint_field')),
        'not a url',
      );
      await tester.enterText(find.byKey(const Key('voice_timeout_field')), '0');
      await tester.tap(find.byKey(const Key('voice_service_save_button')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.enabled, isFalse);
      expect(changedSettings!.timeout, const Duration(seconds: 8));
      expect(find.widgetWithText(TextField, '8'), findsOneWidget);
      expect(find.text('语音服务已关闭'), findsOneWidget);
    });

    testWidgets('tests voice service settings through injected callback',
        (tester) async {
      ChatVoiceSettings? testedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceServicePage(
            onTestVoiceService: (settings) async {
              testedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('voice_endpoint_field')),
        'https://voice.example.com',
      );
      await tester.tap(find.byKey(const Key('voice_service_test_button')));
      await tester.pumpAndSettle();

      expect(testedSettings, isNotNull);
      expect(testedSettings!.enabled, isTrue);
      expect(testedSettings!.endpoint, 'https://voice.example.com');
      expect(find.text('语音服务测试成功'), findsOneWidget);
    });

    testWidgets('requires endpoint before testing voice service',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VoiceServicePage()),
      );

      await tester.tap(find.byKey(const Key('voice_service_test_button')));
      await tester.pump();

      expect(
        find.text('自定义语音服务需要填写 http 或 https 地址'),
        findsOneWidget,
      );
    });
  });

  group('WorldBookPage', () {
    testWidgets('adds a world book entry and reports changes', (tester) async {
      ChatWorldBookSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: WorldBookPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add_world_book_entry_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('world_book_entry_title_field')),
        '实验室',
      );
      await tester.enterText(
        find.byKey(const Key('world_book_entry_keywords_field')),
        '实验室,设备',
      );
      await tester.enterText(
        find.byKey(const Key('world_book_entry_content_field')),
        '设备位于实验室。',
      );
      await tester.tap(find.byKey(const Key('save_world_book_entry_button')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.entries.single.title, '实验室');
      expect(changedSettings!.entries.single.keywords, <String>['实验室', '设备']);
      expect(find.text('实验室'), findsOneWidget);
    });

    testWidgets('clears world book entry validation errors while editing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WorldBookPage()),
      );

      await tester.tap(find.byKey(const Key('add_world_book_entry_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_world_book_entry_button')));
      await tester.pump();

      expect(find.text('标题和内容不能为空'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('world_book_entry_title_field')),
        '实验室',
      );
      await tester.pump();

      expect(find.text('标题和内容不能为空'), findsNothing);
    });

    testWidgets('updates max active entries while editing', (tester) async {
      ChatWorldBookSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: WorldBookPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('world_book_max_entries_field')),
        '8',
      );
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.maxActiveEntries, 8);
    });

    testWidgets('resets max active entries text to the saved clamp',
        (tester) async {
      ChatWorldBookSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: WorldBookPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('world_book_max_entries_field')),
        '0',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.maxActiveEntries, 1);
      expect(find.widgetWithText(TextField, '1'), findsOneWidget);
    });

    testWidgets('toggles and deletes existing world book entries',
        (tester) async {
      ChatWorldBookSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: WorldBookPage(
            settings: const ChatWorldBookSettings(
              entries: <ChatWorldBookEntry>[
                ChatWorldBookEntry(
                  id: 'world-1',
                  title: '实验室',
                  content: '设备在实验室。',
                ),
              ],
            ),
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester
          .tap(find.byKey(const Key('world_book_entry_enabled_world-1')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.entries.single.enabled, isFalse);

      await tester
          .tap(find.byKey(const Key('delete_world_book_entry_world-1')));
      await tester.pump();

      expect(changedSettings!.entries, isEmpty);
      expect(find.text('暂无世界书条目'), findsOneWidget);
    });
  });

  group('PromptInjectionPage', () {
    testWidgets('adds a prompt injection rule and reports changes',
        (tester) async {
      ChatPromptInjectionSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: PromptInjectionPage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add_prompt_rule_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('prompt_rule_title_field')),
        '风格',
      );
      await tester.enterText(
        find.byKey(const Key('prompt_rule_content_field')),
        '保持简洁。',
      );
      await tester.tap(find.byKey(const Key('save_prompt_rule_button')));
      await tester.pumpAndSettle();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.rules.single.title, '风格');
      expect(changedSettings!.rules.single.content, '保持简洁。');
      expect(find.text('风格'), findsOneWidget);
    });

    testWidgets('clears prompt rule validation errors while editing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PromptInjectionPage()),
      );

      await tester.tap(find.byKey(const Key('add_prompt_rule_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_prompt_rule_button')));
      await tester.pump();

      expect(find.text('标题和内容不能为空'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('prompt_rule_title_field')),
        '风格',
      );
      await tester.pump();

      expect(find.text('标题和内容不能为空'), findsNothing);
    });

    testWidgets('toggles and deletes existing prompt injection rules',
        (tester) async {
      ChatPromptInjectionSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: PromptInjectionPage(
            settings: const ChatPromptInjectionSettings(
              rules: <ChatPromptInjectionRule>[
                ChatPromptInjectionRule(
                  id: 'prompt-1',
                  title: '风格',
                  content: '保持简洁。',
                ),
              ],
            ),
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('prompt_rule_enabled_prompt-1')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.rules.single.enabled, isFalse);

      await tester.tap(find.byKey(const Key('delete_prompt_rule_prompt-1')));
      await tester.pump();

      expect(changedSettings!.rules, isEmpty);
      expect(find.text('暂无注入指令'), findsOneWidget);
    });
  });

  group('DataBackupPage', () {
    testWidgets('copies a full settings backup JSON', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DataBackupPage(
            settings: ChatAppSettings(
              quickPhrases: <ChatQuickPhrase>[
                ChatQuickPhrase(
                  id: 'phrase-1',
                  title: '开场白',
                  content: '你好',
                ),
              ],
            ),
            connectionSettings: ChatConnectionSettings(
              host: '192.168.1.10',
              port: 18789,
              clientId: 'barebrain_app',
              responseTimeout: Duration(seconds: 10),
            ),
            displaySettings: ChatDisplaySettings(
              colorMode: ChatColorMode.dark,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('copy_settings_backup_button')));
      await tester.pump();

      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      final backup = jsonDecode(clipboard!.text!) as Map<String, dynamic>;

      expect(backup['version'], 1);
      expect(backup['appSettings'], isA<Map<String, dynamic>>());
      expect(backup['connectionSettings'], isA<Map<String, dynamic>>());
      expect(backup['displaySettings'], isA<Map<String, dynamic>>());
      expect(find.text('设置备份已复制'), findsOneWidget);
    });

    testWidgets('imports settings backup JSON', (tester) async {
      ChatAppSettings? importedSettings;
      const source = ChatAppSettings(
        quickPhrases: <ChatQuickPhrase>[
          ChatQuickPhrase(
            id: 'phrase-1',
            title: '开场白',
            content: '你好',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DataBackupPage(
            onAppSettingsImported: (settings) {
              importedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        ChatAppSettingsCodec.encode(source),
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedSettings, isNotNull);
      expect(importedSettings!.quickPhrases.single.title, '开场白');
      expect(find.text('设置备份已导入'), findsOneWidget);
    });

    testWidgets('imports full settings backup JSON', (tester) async {
      ChatAppSettings? importedAppSettings;
      ChatConnectionSettings? importedConnectionSettings;
      ChatDisplaySettings? importedDisplaySettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DataBackupPage(
            onAppSettingsImported: (settings) {
              importedAppSettings = settings;
            },
            onConnectionSettingsImported: (settings) {
              importedConnectionSettings = settings;
            },
            onDisplaySettingsImported: (settings) {
              importedDisplaySettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '''
{
  "version": 1,
  "appSettings": {
    "version": 1,
    "quickPhrases": [
      {"id": "phrase-1", "title": "开场白", "content": "你好", "enabled": true}
    ]
  },
  "connectionSettings": {
    "host": "10.0.0.2",
    "port": 18789,
    "clientId": "mobile",
    "secure": false,
    "responseTimeoutMs": 10000
  },
  "displaySettings": {
    "colorMode": "dark",
    "themePreset": "graphite"
  }
}
''',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedAppSettings, isNotNull);
      expect(importedAppSettings!.quickPhrases.single.content, '你好');
      expect(importedConnectionSettings, isNotNull);
      expect(importedConnectionSettings!.host, '10.0.0.2');
      expect(importedDisplaySettings, isNotNull);
      expect(importedDisplaySettings!.colorMode, ChatColorMode.dark);
    });

    testWidgets('rejects invalid full backup app settings', (tester) async {
      ChatAppSettings? importedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DataBackupPage(
            onAppSettingsImported: (settings) {
              importedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '{"version":1,"appSettings":null}',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedSettings, isNull);
      expect(find.textContaining('应用设置格式无效'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '{"version":1,"appSettings":"bad"}',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedSettings, isNull);
      expect(find.textContaining('应用设置格式无效'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '{"version":1,"connectionSettings":{}}',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedSettings, isNull);
      expect(find.textContaining('应用设置格式无效'), findsOneWidget);
    });

    testWidgets('rejects invalid optional full backup sections',
        (tester) async {
      ChatAppSettings? importedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: DataBackupPage(
            onAppSettingsImported: (settings) {
              importedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '{"version":1,"appSettings":{},"connectionSettings":"bad"}',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedSettings, isNull);
      expect(find.textContaining('连接设置格式无效'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '{"version":1,"appSettings":{},"displaySettings":"bad"}',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(importedSettings, isNull);
      expect(find.textContaining('显示设置格式无效'), findsOneWidget);
    });

    testWidgets('clears import feedback when backup text changes',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DataBackupPage()),
      );

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        'not json',
      );
      await tester.tap(find.byKey(const Key('import_settings_backup_button')));
      await tester.pump();

      expect(find.textContaining('导入失败'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('settings_backup_import_field')),
        '{}',
      );
      await tester.pump();

      expect(find.textContaining('导入失败'), findsNothing);
    });
  });

  group('ChatStoragePage', () {
    testWidgets('updates storage switches', (tester) async {
      ChatStorageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatStoragePage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('storage_save_drafts_switch')));
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.saveDrafts, isFalse);
    });

    testWidgets('updates max local conversations while editing',
        (tester) async {
      ChatStorageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatStoragePage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('storage_max_conversations_field')),
        '12',
      );
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.maxLocalConversations, 12);
    });

    testWidgets('resets max local conversations text to the saved clamp',
        (tester) async {
      ChatStorageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatStoragePage(
            onChanged: (settings) {
              changedSettings = settings;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('storage_max_conversations_field')),
        '0',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changedSettings, isNotNull);
      expect(changedSettings!.maxLocalConversations, 1);
      expect(find.widgetWithText(TextField, '1'), findsOneWidget);
    });
  });

  group('QuickPhrasesPage', () {
    testWidgets('starts without placeholder quick phrases', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuickPhrasesPage()),
      );

      expect(find.text('ejej'), findsNothing);
      expect(find.text('哎啊啊快啊'), findsNothing);
    });

    testWidgets('adds a local quick phrase from the bottom sheet',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuickPhrasesPage()),
      );

      await tester.tap(find.byKey(const Key('add_quick_phrase_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('quick_phrase_title_field')),
        '开场白',
      );
      await tester.enterText(
        find.byKey(const Key('quick_phrase_content_field')),
        '你好，开始检查状态。',
      );
      await tester.tap(find.byKey(const Key('save_quick_phrase_button')));
      await tester.pumpAndSettle();

      expect(find.text('开场白'), findsOneWidget);
      expect(find.text('你好，开始检查状态。'), findsOneWidget);
    });

    testWidgets('clears quick phrase validation errors while editing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: QuickPhrasesPage()),
      );

      await tester.tap(find.byKey(const Key('add_quick_phrase_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_quick_phrase_button')));
      await tester.pump();

      expect(find.text('标题和内容不能为空'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('quick_phrase_title_field')),
        '开场白',
      );
      await tester.pump();

      expect(find.text('标题和内容不能为空'), findsNothing);
    });

    testWidgets('edits toggles and deletes existing quick phrases',
        (tester) async {
      List<ChatQuickPhrase>? changedPhrases;

      await tester.pumpWidget(
        MaterialApp(
          home: QuickPhrasesPage(
            phrases: const <ChatQuickPhrase>[
              ChatQuickPhrase(
                id: 'phrase-1',
                title: '旧标题',
                content: '旧内容',
              ),
            ],
            onChanged: (phrases) {
              changedPhrases = phrases;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('quick_phrase_enabled_phrase-1')));
      await tester.pump();

      expect(changedPhrases, isNotNull);
      expect(changedPhrases!.single.enabled, isFalse);

      await tester.tap(find.byKey(const Key('edit_quick_phrase_phrase-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('quick_phrase_title_field')),
        '新标题',
      );
      await tester.enterText(
        find.byKey(const Key('quick_phrase_content_field')),
        '新内容',
      );
      await tester.tap(find.byKey(const Key('save_quick_phrase_button')));
      await tester.pumpAndSettle();

      expect(changedPhrases!.single.title, '新标题');
      expect(changedPhrases!.single.content, '新内容');

      await tester.tap(find.byKey(const Key('delete_quick_phrase_phrase-1')));
      await tester.pump();

      expect(changedPhrases, isEmpty);
      expect(find.text('暂无快捷短语'), findsOneWidget);
    });
  });
}

class _FailingAppSettingsStore implements ChatAppSettingsStore {
  @override
  Future<ChatAppSettings?> load() async {
    return null;
  }

  @override
  Future<void> save(ChatAppSettings settings) async {
    throw StateError('disk full');
  }

  @override
  Future<void> clear() async {}
}

class _FailingDisplaySettingsStore implements ChatDisplaySettingsStore {
  @override
  Future<ChatDisplaySettings?> load() async {
    return null;
  }

  @override
  Future<void> save(ChatDisplaySettings settings) async {
    throw StateError('disk full');
  }

  @override
  Future<void> clear() async {}
}
