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
  _PersistentBareBrainConnection? _receiveConnection;

  static const Duration _receiveReconnectDelay = Duration(seconds: 2);

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
  Stream<BareBrainWsPayload> receiveMessages(
    ChatConnectionSettings settings, {
    required String chatId,
  }) {
    final uri = settings.websocketUri;
    final activeConnection = _receiveConnection;
    if (activeConnection != null && activeConnection.matches(uri, chatId)) {
      return activeConnection.stream;
    }

    unawaited(activeConnection?.close());
    final nextConnection = _PersistentBareBrainConnection(
      connectionFactory: _connectionFactory,
      settings: settings,
      chatId: chatId,
      reconnectDelay: _receiveReconnectDelay,
      onClosed: (connection) {
        if (_receiveConnection == connection) {
          _receiveConnection = null;
        }
      },
    );
    _receiveConnection = nextConnection;
    return nextConnection.stream;
  }

  @override
  Future<BareBrainWsPayload> sendMessage(
    String content,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
    final request = BareBrainWsPayload.message(
      content: content,
      chatId: chatId,
      requestId: settings.isRelay ? _newRequestId() : '',
    );

    final activeConnection = _receiveConnection;
    if (activeConnection != null &&
        activeConnection.matches(settings.websocketUri, chatId)) {
      return activeConnection.sendMessage(request);
    }

    return _sendMessageOnNewConnection(
      request,
      settings,
      chatId: chatId,
    );
  }

  Future<BareBrainWsPayload> _sendMessageOnNewConnection(
    BareBrainWsPayload request,
    ChatConnectionSettings settings, {
    required String chatId,
  }) async {
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

      final responseFuture = connection.messages
          .map(BareBrainWsPayload.decode)
          .where((event) {
            return _matchesResponseEvent(
              event,
              chatId: chatId,
              requestId: request.requestId,
            );
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
      final response = await responseFuture;
      if (response.isError) {
        throw ChatConnectionException(response.content);
      }

      return response;
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

  bool _matchesResponseEvent(
    BareBrainWsPayload event, {
    required String chatId,
    required String requestId,
  }) {
    final matchesChatId =
        event.chatId == chatId || (event.isError && event.chatId.isEmpty);
    if (!matchesChatId || (!event.isResponse && !event.isError)) {
      return false;
    }

    return requestId.isEmpty || event.requestId == requestId;
  }

  String _newRequestId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}

class _PersistentBareBrainConnection {
  _PersistentBareBrainConnection({
    required TextSocketConnectionFactory connectionFactory,
    required ChatConnectionSettings settings,
    required String chatId,
    required Duration reconnectDelay,
    required void Function(_PersistentBareBrainConnection connection) onClosed,
  })  : _connectionFactory = connectionFactory,
        _settings = settings,
        _chatId = chatId,
        _uri = settings.websocketUri,
        _reconnectDelay = reconnectDelay,
        _onClosed = onClosed {
    _controller = StreamController<BareBrainWsPayload>.broadcast(
      onListen: () {
        unawaited(_connectSilently());
      },
      onCancel: () {
        unawaited(close());
      },
    );
  }

  final TextSocketConnectionFactory _connectionFactory;
  final ChatConnectionSettings _settings;
  final String _chatId;
  final Uri _uri;
  final Duration _reconnectDelay;
  final void Function(_PersistentBareBrainConnection connection) _onClosed;
  late final StreamController<BareBrainWsPayload> _controller;
  final List<_PendingBareBrainResponse> _pendingResponses =
      <_PendingBareBrainResponse>[];
  TextSocketConnection? _connection;
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;
  Future<void>? _connectFuture;
  bool _closed = false;

  Stream<BareBrainWsPayload> get stream => _controller.stream;

  bool matches(Uri uri, String chatId) {
    return !_closed && _uri == uri && _chatId == chatId;
  }

  Future<BareBrainWsPayload> sendMessage(BareBrainWsPayload request) async {
    try {
      await _connect();

      final connection = _connection;
      if (connection == null) {
        throw const ChatConnectionException('BareBrain 连接已关闭，未收到响应');
      }

      final pending = _PendingBareBrainResponse(
        chatId: _chatId,
        requestId: request.requestId,
      );
      _pendingResponses.add(pending);
      try {
        connection.send(request.encode());
        return await pending.completer.future.timeout(
          _settings.responseTimeout,
          onTimeout: () {
            throw ChatTimeoutException(
              '等待 BareBrain 响应超时：${_settings.responseTimeout.inSeconds} 秒',
            );
          },
        );
      } finally {
        _pendingResponses.remove(pending);
      }
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        '等待 BareBrain 响应超时：${_settings.responseTimeout.inSeconds} 秒',
      );
    } on StateError {
      throw const ChatConnectionException('BareBrain 连接已关闭，未收到响应');
    } catch (error) {
      throw ChatConnectionException('BareBrain 连接失败：$error');
    }
  }

  Future<void> _connectSilently() async {
    try {
      await _connect();
    } catch (_) {
      // The stream already reports connection failures to listeners.
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeConnection();
    await _controller.close();
    _onClosed(this);
  }

  Future<void> _connect() {
    if (_closed) {
      throw const ChatConnectionException('BareBrain 接收通道已关闭');
    }

    final activeConnection = _connection;
    if (activeConnection != null) {
      return activeConnection.ready;
    }

    final activeConnectFuture = _connectFuture;
    if (activeConnectFuture != null) {
      return activeConnectFuture;
    }

    final connectFuture = _connectOnce();
    _connectFuture = connectFuture;
    return connectFuture.whenComplete(() {
      if (_connectFuture == connectFuture) {
        _connectFuture = null;
      }
    });
  }

  Future<void> _connectOnce() async {
    if (_closed) {
      return;
    }

    await _closeConnection();
    final activeConnection = _connectionFactory(_uri);
    _connection = activeConnection;

    try {
      await activeConnection.ready.timeout(
        _settings.responseTimeout,
        onTimeout: () {
          throw ChatTimeoutException(
            '连接 BareBrain 接收通道超时：${_settings.responseTimeout.inSeconds} 秒',
          );
        },
      );

      if (_closed || _connection != activeConnection) {
        await activeConnection.close();
        return;
      }

      _subscription = activeConnection.messages.listen(
        _handleIncomingFrame,
        onError: (Object error, StackTrace stackTrace) {
          if (_closed) {
            return;
          }

          _controller.addError(
            ChatConnectionException('BareBrain 接收通道失败：$error'),
            stackTrace,
          );
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );
    } on ChatException catch (error, stackTrace) {
      if (!_closed) {
        _controller.addError(error, stackTrace);
        _scheduleReconnect();
      }
      rethrow;
    } on TimeoutException catch (_, stackTrace) {
      final error = ChatTimeoutException(
        '连接 BareBrain 接收通道超时：${_settings.responseTimeout.inSeconds} 秒',
      );
      if (!_closed) {
        _controller.addError(error, stackTrace);
        _scheduleReconnect();
      }
      throw error;
    } catch (error, stackTrace) {
      final wrappedError = ChatConnectionException('BareBrain 接收通道连接失败：$error');
      if (!_closed) {
        _controller.addError(wrappedError, stackTrace);
        _scheduleReconnect();
      }
      throw wrappedError;
    }
  }

  void _handleIncomingFrame(String source) {
    try {
      final event = BareBrainWsPayload.decode(source);
      if (_completePendingResponse(event)) {
        return;
      }

      if (event.isError && _matchesChatId(event)) {
        _controller.addError(ChatConnectionException(event.content));
        return;
      }

      if (event.isIncoming && _matchesChatId(event)) {
        _controller.add(event);
      }
    } on ChatException catch (error, stackTrace) {
      _controller.addError(error, stackTrace);
    } catch (error, stackTrace) {
      _controller.addError(
        ChatProtocolException('BareBrain 主动消息解析失败：$error'),
        stackTrace,
      );
    }
  }

  bool _completePendingResponse(BareBrainWsPayload event) {
    if (!event.isResponse && !event.isError) {
      return false;
    }

    for (final pending
        in List<_PendingBareBrainResponse>.of(_pendingResponses)) {
      if (!_matchesPendingResponse(event, pending)) {
        continue;
      }

      if (event.isError) {
        pending.completer.completeError(ChatConnectionException(event.content));
        return true;
      }

      pending.completer.complete(event);
      return true;
    }

    return false;
  }

  bool _matchesPendingResponse(
    BareBrainWsPayload event,
    _PendingBareBrainResponse pending,
  ) {
    final matchesChatId = event.chatId == pending.chatId ||
        (event.isError && event.chatId.isEmpty);
    if (!matchesChatId) {
      return false;
    }

    return pending.requestId.isEmpty || event.requestId == pending.requestId;
  }

  bool _matchesChatId(BareBrainWsPayload event) {
    return event.chatId.isEmpty || event.chatId == _chatId;
  }

  void _scheduleReconnect() {
    if (_closed) {
      return;
    }

    unawaited(_closeConnection());
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      unawaited(_connectSilently());
    });
  }

  Future<void> _closeConnection() async {
    await _subscription?.cancel();
    _subscription = null;
    for (final pending
        in List<_PendingBareBrainResponse>.of(_pendingResponses)) {
      pending.completer.completeError(
        const ChatConnectionException('BareBrain 连接已关闭，未收到响应'),
      );
    }
    _pendingResponses.clear();
    await _connection?.close();
    _connection = null;
  }
}

class _PendingBareBrainResponse {
  _PendingBareBrainResponse({
    required this.chatId,
    required this.requestId,
  });

  final String chatId;
  final String requestId;
  final Completer<BareBrainWsPayload> completer =
      Completer<BareBrainWsPayload>();
}
