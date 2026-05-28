import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/presentation/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsSheet', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    testWidgets('tests connection with current form settings', (tester) async {
      ChatConnectionSettings? testedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSheet(
              settings: settings,
              onTestConnection: (settings) async {
                testedSettings = settings;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('测试连接'));
      await tester.pump();
      await tester.pump();

      expect(testedSettings, isNotNull);
      expect(
        testedSettings!.websocketUri.toString(),
        'ws://192.168.1.10:18789/',
      );
      expect(find.text('连接成功'), findsOneWidget);
    });

    testWidgets('clears connection test feedback when form changes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSheet(
              settings: settings,
              onTestConnection: (_) async {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('测试连接'));
      await tester.pump();
      await tester.pump();

      expect(find.text('连接成功'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('connection_host_field')),
        '10.0.0.2',
      );
      await tester.pump();

      expect(find.text('连接成功'), findsNothing);
    });
  });
}
