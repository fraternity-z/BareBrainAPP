import '../../../../core/errors/chat_exception.dart';

class ChatRouteIdBuilder {
  const ChatRouteIdBuilder._();

  static const maxLength = 31;
  static final _allowed = RegExp(r'^[A-Za-z0-9_.-]+$');
  static final _unsafe = RegExp(r'[^A-Za-z0-9_.-]+');
  static final _repeatedDash = RegExp(r'-+');
  static final _edgeSeparators = RegExp(r'^[-_.]+|[-_.]+$');

  static String build({
    required String clientId,
    required String conversationId,
  }) {
    final base = _sanitize(clientId);
    final routeSeed = _sanitize(conversationId);

    if (routeSeed == 'default') {
      return _fit(base);
    }

    final readable = '$base-$routeSeed';
    if (readable.length <= maxLength) {
      return readable;
    }

    final suffix = _hash(routeSeed);
    const separator = '-';
    final prefix = _fit(
      base,
      limit: maxLength - separator.length - suffix.length,
    );
    return '$prefix$separator$suffix';
  }

  static void validate(String chatId) {
    final normalized = chatId.trim();
    if (normalized.isEmpty) {
      throw const ChatValidationException('BareBrain chat_id 不能为空');
    }

    if (normalized.length > maxLength) {
      throw const ChatValidationException('BareBrain chat_id 不能超过 31 个字符');
    }

    if (!_allowed.hasMatch(normalized)) {
      throw const ChatValidationException(
        'BareBrain chat_id 只能包含字母、数字、下划线、点和短横线',
      );
    }
  }

  static String _sanitize(String value) {
    final normalized = value.trim().replaceAll(_unsafe, '-');
    final collapsed = normalized.replaceAll(_repeatedDash, '-');
    final trimmed = collapsed.replaceAll(_edgeSeparators, '');
    return trimmed.isEmpty ? 'barebrain' : trimmed;
  }

  static String _fit(String value, {int limit = maxLength}) {
    if (value.length <= limit) {
      return value;
    }

    final trimmed = value.substring(0, limit).replaceAll(
          _edgeSeparators,
          '',
        );
    return trimmed.isEmpty ? 'barebrain' : trimmed;
  }

  static String _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return hash.toRadixString(36).padLeft(6, '0').substring(0, 6);
  }
}
