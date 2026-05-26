import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/display_settings_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/network_proxy_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/quick_phrases_page.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/settings_components.dart';
import 'package:bare_brain_app/src/features/chat/presentation/settings/settings_page.dart';
import 'package:flutter/material.dart';
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
      expect(find.byKey(const Key('proxy_test_button')), findsOneWidget);
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

      expect(find.text('https://www.google.com'), findsOneWidget);
    });

    testWidgets('toggles proxy type and validates test URL', (tester) async {
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

      await tester.tap(find.byKey(const Key('proxy_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SOCKS5').last);
      await tester.pumpAndSettle();

      expect(find.text('SOCKS5'), findsOneWidget);

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

      expect(find.text('配置检查通过：SOCKS5 127.0.0.1:8080'), findsOneWidget);
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
  });
}
