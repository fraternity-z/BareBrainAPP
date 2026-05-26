import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_connection_settings.dart';

class ChatConnectionSettingsCodec {
  const ChatConnectionSettingsCodec._();

  static Map<String, dynamic> toJson(ChatConnectionSettings settings) {
    return <String, dynamic>{
      'host': settings.host,
      'port': settings.port,
      'clientId': settings.clientId,
      'responseTimeoutMs': settings.responseTimeout.inMilliseconds,
      'secure': settings.secure,
    };
  }

  static ChatConnectionSettings fromJson(Map<String, dynamic> value) {
    final host = value['host'];
    final port = value['port'];
    final clientId = value['clientId'];
    final responseTimeoutMs = value['responseTimeoutMs'];
    final secure = value['secure'];

    if (host is! String ||
        port is! int ||
        clientId is! String ||
        responseTimeoutMs is! int) {
      throw const ChatStorageException('会话连接设置格式错误');
    }

    return ChatConnectionSettings(
      host: host,
      port: port,
      clientId: clientId,
      responseTimeout: Duration(milliseconds: responseTimeoutMs),
      secure: secure is bool ? secure : false,
    );
  }
}
