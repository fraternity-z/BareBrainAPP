import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

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
  }) : _channel = (channelFactory ?? WebSocketChannel.connect)(uri);

  final WebSocketChannel _channel;

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
    await _channel.sink.close(status.normalClosure).catchError((Object _) {});
  }
}
