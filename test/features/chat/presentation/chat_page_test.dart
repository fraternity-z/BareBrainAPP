import 'package:bare_brain_app/src/features/chat/data/repositories/memory_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:bare_brain_app/src/features/chat/domain/usecases/send_chat_message.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_controller.dart';
import 'package:bare_brain_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatPage', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(seconds: 10),
    );

    testWidgets('syncs composer when a restored draft arrives', (tester) async {
      final store = MemoryChatSessionStore();
      await store.save(
        const ChatSessionSnapshot(
          settings: settings,
          messages: [],
          draft: 'half typed',
        ),
      );
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
        sessionStore: store,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      expect(_composerText(tester), isEmpty);

      await controller.restore();
      await tester.pump();

      expect(_composerText(tester), 'half typed');

      controller.dispose();
    });

    testWidgets('renders composer as a clean rounded input panel',
        (tester) async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.focusedBorder, InputBorder.none);

      final composerSurface = tester.widget<DecoratedBox>(
        find.byKey(const Key('chat_composer_surface')),
      );
      final decoration = composerSurface.decoration;

      expect(decoration, isA<BoxDecoration>());
      expect(
        (decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(32),
      );
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNull);

      controller.dispose();
    });

    testWidgets('renders an animated empty message illustration',
        (tester) async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      expect(find.byKey(const Key('empty_message_animation')), findsOneWidget);
      expect(find.text('暂无消息'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byKey(const Key('empty_message_animation')), findsOneWidget);

      controller.dispose();
    });

    testWidgets('moves conversation actions into the long press menu',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );
      await controller.createConversation(title: 'Work');

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      expect(find.byTooltip('重命名会话'), findsNothing);
      expect(find.byTooltip('删除会话'), findsNothing);

      await tester.longPress(find.text('BareBrain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);

      await tester.tap(find.text('删除'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        controller.conversations.map((conversation) => conversation.title),
        isNot(contains('BareBrain')),
      );

      controller.dispose();
    });

    testWidgets('hides desktop sidebar and restores it from header',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      expect(
        tester.getSize(find.byKey(const Key('chat_sidebar'))).width,
        280,
      );
      expect(
        tester.getSize(find.byKey(const Key('desktop_sidebar_slot'))).width,
        280,
      );
      expect(find.text('会话'), findsOneWidget);
      expect(find.text('BareBrain'), findsNothing);

      final foldGesture = await tester.startGesture(
        tester.getCenter(find.byTooltip('折叠侧栏')),
      );
      await tester.pump();
      await foldGesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final collapsingWidth =
          tester.getSize(find.byKey(const Key('desktop_sidebar_slot'))).width;
      expect(collapsingWidth, greaterThan(0));
      expect(collapsingWidth, lessThan(280));

      await tester.pump(const Duration(milliseconds: 260));

      expect(find.byKey(const Key('chat_sidebar')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('desktop_sidebar_slot'))).width,
        0,
      );
      expect(find.byTooltip('展开侧栏'), findsOneWidget);

      await tester.tap(find.byTooltip('展开侧栏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final expandingWidth =
          tester.getSize(find.byKey(const Key('desktop_sidebar_slot'))).width;
      expect(expandingWidth, greaterThan(0));
      expect(expandingWidth, lessThan(280));

      await tester.pump(const Duration(milliseconds: 260));

      expect(
        tester.getSize(find.byKey(const Key('chat_sidebar'))).width,
        280,
      );
      expect(find.text('会话'), findsOneWidget);

      await tester.tap(find.text('新对话'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.byKey(const Key('chat_sidebar')), findsNothing);

      controller.dispose();
    });

    testWidgets('sizes mobile drawer to eighty percent up to max width',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );

      await tester.pumpWidget(
        MaterialApp(home: ChatPage(controller: controller)),
      );

      await tester.tap(find.byTooltip('会话'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.getSize(find.byKey(const Key('chat_sidebar'))).width,
        288,
      );

      controller.dispose();
    });
  });
}

String _composerText(WidgetTester tester) {
  final textField = tester.widget<TextField>(find.byType(TextField));
  return textField.controller!.text;
}

class _FakeRepository implements ChatRepository {
  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    return 'pong';
  }
}
