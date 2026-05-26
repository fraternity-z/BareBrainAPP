class ChatMessageTimeFormatter {
  const ChatMessageTimeFormatter._();

  static String format(DateTime time) {
    final local = time.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${_twoDigits(local.month)}-'
        '${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:'
        '${_twoDigits(local.minute)}';
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
