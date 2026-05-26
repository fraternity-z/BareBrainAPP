import 'package:bare_brain_app/src/features/chat/domain/services/chat_conversation_title_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatConversationTitleBuilder', () {
    test('normalizes whitespace from first message', () {
      final title = ChatConversationTitleBuilder.fromMessage(
        '  summarize\nBareBrain   status  ',
      );

      expect(title, 'summarize BareBrain status');
    });

    test('truncates long messages', () {
      final title = ChatConversationTitleBuilder.fromMessage(
        'abcdefghijklmnopqrstuvwxyz0123456789-extra',
      );

      expect(title.length, ChatConversationTitleBuilder.maxLength);
      expect(title.endsWith('...'), isTrue);
    });
  });
}
