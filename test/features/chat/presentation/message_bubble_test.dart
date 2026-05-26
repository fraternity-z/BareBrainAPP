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
  });
}
