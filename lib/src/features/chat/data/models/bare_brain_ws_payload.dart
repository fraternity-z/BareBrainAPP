import 'dart:convert';

import '../../../../core/errors/chat_exception.dart';

class BareBrainWsPayload {
  const BareBrainWsPayload({
    required this.type,
    required this.content,
    required this.chatId,
    this.requestId = '',
  });

  factory BareBrainWsPayload.message({
    required String content,
    required String chatId,
    String requestId = '',
  }) {
    return BareBrainWsPayload(
      type: 'message',
      content: content,
      chatId: chatId,
      requestId: requestId,
    );
  }

  factory BareBrainWsPayload.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ChatProtocolException('BareBrain 返回了无效 JSON');
    }

    final type = value['type'];
    final content = value['content'];
    final chatId = value['chat_id'];
    final requestId = value['request_id'];

    if (type is! String) {
      throw const ChatProtocolException('BareBrain 响应缺少必要字段');
    }

    if (type == 'error') {
      final message = value['message'];
      if (message is! String) {
        throw const ChatProtocolException('BareBrain 错误响应缺少消息');
      }

      return BareBrainWsPayload(
        type: type,
        content: message,
        chatId: chatId is String ? chatId : '',
        requestId: requestId is String ? requestId : '',
      );
    }

    if (content is! String || chatId is! String) {
      throw const ChatProtocolException('BareBrain 响应缺少必要字段');
    }

    return BareBrainWsPayload(
      type: type,
      content: content,
      chatId: chatId,
      requestId: requestId is String ? requestId : '',
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
  final String requestId;

  bool get isResponse => type == 'response';
  bool get isError => type == 'error';
  bool get isIncoming {
    return type == 'response' || type == 'message' || type == 'event';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'content': content,
      'chat_id': chatId,
      if (requestId.isNotEmpty) 'request_id': requestId,
    };
  }

  String encode() => jsonEncode(toJson());
}
