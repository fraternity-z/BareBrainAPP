import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/entities/chat_app_settings.dart';
import 'proxy_http_client_factory.dart';

abstract class TextSocketConnection {
  Future<void> get ready;
  Stream<String> get messages;

  void send(String text);
  Future<void> close();
}

typedef TextSocketConnectionFactory = TextSocketConnection Function(Uri uri);
typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

class WebSocketTextSocketConnection implements TextSocketConnection {
  WebSocketTextSocketConnection(
    Uri uri, {
    WebSocketChannelFactory? channelFactory,
    ChatNetworkProxySettings? networkProxySettings,
  }) : _resources = _createResources(
          uri,
          channelFactory: channelFactory,
          networkProxySettings: networkProxySettings,
        );

  final _WebSocketConnectionResources _resources;

  WebSocketChannel get _channel => _resources.channel;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<String> get messages {
    return _channel.stream.where((event) => event is String).cast<String>();
  }

  @override
  void send(String text) {
    _channel.sink.add(text);
  }

  @override
  Future<void> close() async {
    try {
      await _channel.sink.close(status.normalClosure).catchError((Object _) {});
    } finally {
      _resources.httpClient?.close(force: true);
    }
  }

  static _WebSocketConnectionResources _createResources(
    Uri uri, {
    WebSocketChannelFactory? channelFactory,
    ChatNetworkProxySettings? networkProxySettings,
  }) {
    if (channelFactory != null) {
      return _WebSocketConnectionResources(channel: channelFactory(uri));
    }

    final proxySettings = networkProxySettings;
    if (proxySettings == null || !proxySettings.enabled) {
      return _WebSocketConnectionResources(
        channel: WebSocketChannel.connect(uri),
      );
    }

    final client = ProxyHttpClientFactory.create(settings: proxySettings);

    return _WebSocketConnectionResources(
      channel: IOWebSocketChannel.connect(uri, customClient: client),
      httpClient: client,
    );
  }
}

class _WebSocketConnectionResources {
  const _WebSocketConnectionResources({
    required this.channel,
    this.httpClient,
  });

  final WebSocketChannel channel;
  final HttpClient? httpClient;
}
