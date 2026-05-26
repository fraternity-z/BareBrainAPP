import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_message.dart';
import 'package:bare_brain_app/src/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('exposes copy action for message content', (tester) async {
      var copied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: 'm1',
                author: ChatMessageAuthor.assistant,
                content: 'copy me',
                createdAt: DateTime(2026),
              ),
              onCopy: () => copied = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.copy_all_outlined));

      expect(copied, isTrue);
    });

    testWidgets('renders message timestamp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: 'm1',
                author: ChatMessageAuthor.assistant,
                content: 'hello',
                createdAt: DateTime(2026, 5, 25, 8, 3),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2026-05-25 08:03'), findsOneWidget);
    });

    testWidgets('hides timestamp and copy action from display settings',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              displaySettings: const ChatDisplaySettings(
                showMessageTimestamps: false,
                showMessageActions: false,
              ),
              message: ChatMessage(
                id: 'm1',
                author: ChatMessageAuthor.assistant,
                content: 'hello',
                createdAt: DateTime(2026, 5, 25, 8, 3),
              ),
              onCopy: () {},
            ),
          ),
        ),
      );

      expect(find.text('2026-05-25 08:03'), findsNothing);
      expect(find.byIcon(Icons.copy_all_outlined), findsNothing);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('can render message content as plain text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              displaySettings: const ChatDisplaySettings(
                selectableMessageText: false,
              ),
              message: ChatMessage(
                id: 'm1',
                author: ChatMessageAuthor.assistant,
                content: 'plain text',
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SelectableText), findsNothing);
      expect(find.text('plain text'), findsOneWidget);
    });

    testWidgets('uses configured code font for fenced code blocks',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              displaySettings: const ChatDisplaySettings(
                codeFont: ChatCodeFont.mono,
              ),
              message: ChatMessage(
                id: 'm1',
                author: ChatMessageAuthor.assistant,
                content: '说明\n```dart\nvoid main() {}\n```',
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ),
      );

      final text = tester.widget<SelectableText>(find.byType(SelectableText));

      expect(text.style?.fontFamily, 'Consolas');
    });

    testWidgets('applies the configured message background style',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              displaySettings: const ChatDisplaySettings(
                messageBackground: ChatMessageBackground.plain,
              ),
              message: ChatMessage(
                id: 'm1',
                author: ChatMessageAuthor.user,
                content: 'plain bubble',
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ),
      );

      final bubble = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MessageBubble),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      final decoration = bubble.decoration as BoxDecoration;
      final colors =
          Theme.of(tester.element(find.text('plain bubble'))).colorScheme;

      expect(decoration.color, colors.surfaceContainerLowest);
      expect((decoration.border as Border).top.color, colors.primary);
    });
  });
}
