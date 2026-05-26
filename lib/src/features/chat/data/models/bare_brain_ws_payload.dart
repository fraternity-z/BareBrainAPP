import 'dart:convert';

import '../../../../core/errors/chat_exception.dart';

class BareBrainWsPayload {
  const BareBrainWsPayload({
    required this.type,
    required this.content,
    required this.chatId,
  });

  factory BareBrainWsPayload.message({
    required String content,
    required String chatId,
  }) {
    return BareBrainWsPayload(
      type: 'message',
      content: content,
      chatId: chatId,
    );
  }

  factory BareBrainWsPayload.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ChatProtocolException('BareBrain 返回了无效 JSON');
    }

    final type = value['type'];
    final content = value['content'];
    final chatId = value['chat_id'];

    if (type is! String || content is! String || chatId is! String) {
      throw const ChatProtocolException('BareBrain 响应缺少必要字段');
    }

    return BareBrainWsPayload(
      type: type,
      content: content,
      chatId: chatId,
    );
  }

  factory BareBrainWsPayload.decode(String source) {
    try {
      return BareBrainWsPayload.fromJson(jsonDecode(source));
    } on ChatProtocolException {
      rethrow;
    } on FormatException {
      throw const ChatProtocolException('BareBrain 返回了无法解析的 JSON');
    }
  }

  final String type;
  final String content;
  final String chatId;

  bool get isResponse => type == 'response';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'content': content,
      'chat_id': chatId,
    };
  }

  String encode() => jsonEncode(toJson());
}
