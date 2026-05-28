import 'dart:async';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../models/bare_brain_ws_payload.dart';
import 'chat_transport.dart';
import 'text_socket_connection.dart';

class BareBrainWebSocketTransport implements ChatTransport {
  BareBrainWebSocketTransport({
    TextSocketConnectionFactory? connectionFactory,
    ChatNetworkProxySettings Function()? networkProxySettingsProvider,
  }) : _connectionFactory = connectionFactory ??
            ((uri) => WebSocketTextSocketConnection(
                  uri,
                  networkProxySettings: networkProxySettingsProvider?.call(),
                ));

  final TextSocketConnectionFactory _connectionFactory;

  @override
  Future<void> checkConnection(ChatConnectionSettings settings) async {
    final connection = _connectionFactory(settings.websocketUri);

    try {
      await connection.ready.timeout(
        settings.responseTimeout,
        onTimeout: () {
          throw ChatTimeoutException(
            '连接 BareBrain 超时：${settings.responseTimeout.inSeconds} 秒',
          );
        },
      );
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        '连接 BareBrain 超时：${settings.responseTimeout.inSeconds} 秒',
      );
    } catch (error) {
      throw ChatConnectionException('BareBrain 连接失败：$error');
    } finally {
      await connection.close();
    }
  }

  @override
  Future<BareBrainWsPayload> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    final connection = _connectionFactory(settings.websocketUri);
    final request = BareBrainWsPayload.message(
      content: content,
      chatId: chatId,
    );

    try {
      await connection.ready.timeout(
        settings.responseTimeout,
        onTimeout: () {
          throw ChatTimeoutException(
            '连接 BareBrain 超时：${settings.responseTimeout.inSeconds} 秒',
          );
        },
      );

      final responseFuture = connection.messages
          .map(BareBrainWsPayload.decode)
          .where((event) {
            return event.isResponse && event.chatId == chatId;
          })
          .first
          .timeout(
            settings.responseTimeout,
            onTimeout: () {
              throw ChatTimeoutException(
                '等待 BareBrain 响应超时：${settings.responseTimeout.inSeconds} 秒',
              );
            },
          );

      connection.send(request.encode());
      return await responseFuture;
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        '等待 BareBrain 响应超时：${settings.responseTimeout.inSeconds} 秒',
      );
    } on StateError {
      throw const ChatConnectionException('BareBrain 连接已关闭，未收到响应');
    } catch (error) {
      throw ChatConnectionException('BareBrain 连接失败：$error');
    } finally {
      await connection.close();
    }
  }
}
