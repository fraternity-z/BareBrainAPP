import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:bare_brain_app/src/features/chat/data/repositories/memory_chat_session_store.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_session_snapshot.dart';
import 'package:bare_brain_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:bare_brain_app/src/features/chat/domain/usecases/send_chat_message.dart';
import 'package:bare_brain_app/src/features/chat/presentation/controllers/chat_app_settings_controller.dart';
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

    testWidgets('applies display font scale to the composer', (tester) async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            controller: controller,
            displaySettings: const ChatDisplaySettings(messageFontScale: 1.25),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.style?.fontSize, 17.5);

      controller.dispose();
    });

    testWidgets('applies display background mask to the chat surface',
        (tester) async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            controller: controller,
            displaySettings: const ChatDisplaySettings(
              backgroundMaskOpacity: 0,
            ),
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const Key('chat_surface')),
      );
      final decoration = surface.decoration as BoxDecoration;
      final colors = Theme.of(
        tester.element(find.byKey(const Key('chat_surface'))),
      ).colorScheme;
      final expected = Color.alphaBlend(
        colors.surfaceContainerLow.withValues(alpha: 0),
        colors.surfaceContainerHigh.withValues(alpha: 0.32),
      );

      expect(decoration.color, expected);

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

    testWidgets('opens settings from the desktop sidebar footer',
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

      expect(find.byTooltip('连接设置'), findsNothing);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('通用设置'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('opens settings from the mobile drawer footer', (tester) async {
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

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('通用设置'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('inserts enabled quick phrases into the composer',
        (tester) async {
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
      );
      final appSettingsController = ChatAppSettingsController(
        initialSettings: const ChatAppSettings(
          quickPhrases: <ChatQuickPhrase>[
            ChatQuickPhrase(
              id: 'phrase-1',
              title: '开场白',
              content: '你好，开始检查状态。',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            controller: controller,
            appSettingsController: appSettingsController,
          ),
        ),
      );

      await tester.tap(find.byTooltip('快捷短语'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('quick_phrase_picker_phrase-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_composerText(tester), '你好，开始检查状态。');
      expect(controller.draft, '你好，开始检查状态。');

      controller.dispose();
      appSettingsController.dispose();
    });

    testWidgets('syncs storage settings before saving composer drafts',
        (tester) async {
      final store = MemoryChatSessionStore();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(_FakeRepository()),
        initialSettings: settings,
        sessionStore: store,
      );
      final appSettingsController = ChatAppSettingsController(
        initialSettings: const ChatAppSettings(
          storage: ChatStorageSettings(saveDrafts: false),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            controller: controller,
            appSettingsController: appSettingsController,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'half typed');
      await tester.pump();
      await Future<void>.delayed(Duration.zero);

      final snapshot = await store.load();

      expect(controller.draft, 'half typed');
      expect(snapshot, isNotNull);
      expect(snapshot!.draft, isEmpty);

      controller.dispose();
      appSettingsController.dispose();
    });

    testWidgets('sends world book and prompt injection as transport content',
        (tester) async {
      final repository = _FakeRepository();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(repository),
        initialSettings: settings,
      );
      final appSettingsController = ChatAppSettingsController(
        initialSettings: const ChatAppSettings(
          worldBook: ChatWorldBookSettings(
            entries: <ChatWorldBookEntry>[
              ChatWorldBookEntry(
                id: 'world-1',
                title: '实验室',
                content: '设备位于实验室。',
                keywords: <String>['实验室'],
              ),
            ],
          ),
          promptInjection: ChatPromptInjectionSettings(
            rules: <ChatPromptInjectionRule>[
              ChatPromptInjectionRule(
                id: 'prompt-1',
                title: '风格',
                content: '保持简洁。',
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            controller: controller,
            appSettingsController: appSettingsController,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '检查实验室状态');
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(repository.contents.single, contains('[世界书：实验室]'));
      expect(repository.contents.single, contains('[系统指令：风格]'));
      expect(repository.contents.single, contains('检查实验室状态'));
      expect(controller.messages.first.content, '检查实验室状态');

      controller.dispose();
      appSettingsController.dispose();
    });

    testWidgets('retries with world book and prompt injection content',
        (tester) async {
      final repository = _RetryRepository();
      final controller = ChatController(
        sendChatMessage: SendChatMessage(repository),
        initialSettings: settings,
      );
      final appSettingsController = ChatAppSettingsController(
        initialSettings: const ChatAppSettings(
          worldBook: ChatWorldBookSettings(
            entries: <ChatWorldBookEntry>[
              ChatWorldBookEntry(
                id: 'world-1',
                title: '实验室',
                content: '设备位于实验室。',
                keywords: <String>['实验室'],
              ),
            ],
          ),
          promptInjection: ChatPromptInjectionSettings(
            rules: <ChatPromptInjectionRule>[
              ChatPromptInjectionRule(
                id: 'prompt-1',
                title: '风格',
                content: '保持简洁。',
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatPage(
            controller: controller,
            appSettingsController: appSettingsController,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '检查实验室状态');
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '重试'));
      await tester.pumpAndSettle();

      expect(repository.contents, hasLength(2));
      expect(repository.contents.last, contains('[世界书：实验室]'));
      expect(repository.contents.last, contains('[系统指令：风格]'));
      expect(repository.contents.last, contains('检查实验室状态'));
      expect(controller.messages.first.content, '检查实验室状态');

      controller.dispose();
      appSettingsController.dispose();
    });
  });
}

String _composerText(WidgetTester tester) {
  final textField = tester.widget<TextField>(find.byType(TextField));
  return textField.controller!.text;
}

class _FakeRepository implements ChatRepository {
  final List<String> contents = <String>[];

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    contents.add(content);
    return 'pong';
  }
}

class _RetryRepository implements ChatRepository {
  final List<String> contents = <String>[];

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {}

  @override
  Future<String> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    contents.add(content);
    if (contents.length == 1) {
      throw const ChatConnectionException('offline');
    }

    return 'pong';
  }
}
