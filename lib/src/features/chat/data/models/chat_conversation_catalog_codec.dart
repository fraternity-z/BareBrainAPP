import 'dart:convert';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_conversation_catalog.dart';
import '../../domain/entities/chat_conversation_summary.dart';
import 'chat_connection_settings_codec.dart';

class ChatConversationCatalogCodec {
  const ChatConversationCatalogCodec._();

  static String encode(ChatConversationCatalog catalog) {
    return jsonEncode(<String, dynamic>{
      'version': 1,
      'activeConversationId': catalog.activeConversationId,
      'conversations': catalog.conversations.map(_summaryToJson).toList(),
    });
  }

  static ChatConversationCatalog decode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) {
        throw const ChatStorageException('会话目录格式错误');
      }

      final activeConversationId = value['activeConversationId'];
      final conversations = value['conversations'];
      if (activeConversationId is! String || conversations is! List) {
        throw const ChatStorageException('会话目录缺少必要字段');
      }

      return ChatConversationCatalog(
        activeConversationId: activeConversationId,
        conversations: conversations.map(_summaryFromJson).toList(
              growable: false,
            ),
      );
    } on ChatStorageException {
      rethrow;
    } on FormatException {
      throw const ChatStorageException('会话目录不是有效 JSON');
    }
  }

  static Map<String, dynamic> _summaryToJson(
    ChatConversationSummary summary,
  ) {
    return <String, dynamic>{
      'id': summary.id,
      'title': summary.title,
      'settings': ChatConnectionSettingsCodec.toJson(summary.settings),
      'updatedAt': summary.updatedAt.toUtc().toIso8601String(),
      'messageCount': summary.messageCount,
      'lastMessagePreview': summary.lastMessagePreview,
    };
  }

  static ChatConversationSummary _summaryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ChatStorageException('会话摘要格式错误');
    }

    final id = value['id'];
    final title = value['title'];
    final settings = value['settings'];
    final updatedAt = value['updatedAt'];
    final messageCount = value['messageCount'];
    final lastMessagePreview = value['lastMessagePreview'];

    if (id is! String ||
        title is! String ||
        settings is! Map<String, dynamic> ||
        updatedAt is! String ||
        messageCount is! int) {
      throw const ChatStorageException('会话摘要缺少必要字段');
    }

    return ChatConversationSummary(
      id: id,
      title: title,
      settings: ChatConnectionSettingsCodec.fromJson(settings),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      messageCount: messageCount,
      lastMessagePreview:
          lastMessagePreview is String ? lastMessagePreview : '',
    );
  }
}
