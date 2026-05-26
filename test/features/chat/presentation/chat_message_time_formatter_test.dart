import 'package:bare_brain_app/src/features/chat/presentation/formatters/chat_message_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessageTimeFormatter', () {
    test('formats local date and minute precision', () {
      final formatted = ChatMessageTimeFormatter.format(
        DateTime(2026, 5, 25, 8, 3, 42),
      );

      expect(formatted, '2026-05-25 08:03');
    });
  });
}
