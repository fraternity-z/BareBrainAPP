import 'dart:convert';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session_snapshot.dart';
import 'chat_connection_settings_codec.dart';

class ChatSessionSnapshotCodec {
  const ChatSessionSnapshotCodec._();

  static String encode(ChatSessionSnapshot snapshot) {
    return jsonEncode(<String, dynamic>{
      'version': 1,
      'settings': ChatConnectionSettingsCodec.toJson(snapshot.settings),
      'messages': snapshot.messages.map(_messageToJson).toList(),
      'draft': snapshot.draft,
    });
  }

  static ChatSessionSnapshot decode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) {
        throw const ChatStorageException('会话快照格式错误');
      }

      final settings = value['settings'];
      final messages = value['messages'];
      final draft = value['draft'];
      if (settings is! Map<String, dynamic> || messages is! List) {
        throw const ChatStorageException('会话快照缺少必要字段');
      }

      return ChatSessionSnapshot(
        settings: ChatConnectionSettingsCodec.fromJson(settings),
        messages: messages.map(_messageFromJson).toList(growable: false),
        draft: draft is String ? draft : '',
      );
    } on ChatStorageException {
      rethrow;
    } on FormatException {
      throw const ChatStorageException('会话快照不是有效 JSON');
    }
  }

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return <String, dynamic>{
      'id': message.id,
      'author': message.author.name,
      'content': message.content,
      'createdAt': message.createdAt.toUtc().toIso8601String(),
      'isPending': message.isPending,
      'error': message.error,
    };
  }

  static ChatMessage _messageFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ChatStorageException('会话消息格式错误');
    }

    final id = value['id'];
    final author = value['author'];
    final content = value['content'];
    final createdAt = value['createdAt'];
    final isPending = value['isPending'];
    final error = value['error'];

    if (id is! String ||
        author is! String ||
        content is! String ||
        createdAt is! String) {
      throw const ChatStorageException('会话消息缺少必要字段');
    }

    return ChatMessage(
      id: id,
      author: _authorFromJson(author),
      content: content,
      createdAt: DateTime.parse(createdAt).toLocal(),
      isPending: isPending is bool ? isPending : false,
      error: error is String ? error : null,
    );
  }

  static ChatMessageAuthor _authorFromJson(String value) {
    for (final author in ChatMessageAuthor.values) {
      if (author.name == value) {
        return author;
      }
    }

    throw const ChatStorageException('会话消息作者类型未知');
  }
}
