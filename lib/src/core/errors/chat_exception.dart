class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChatValidationException extends ChatException {
  const ChatValidationException(super.message);
}

class ChatConnectionException extends ChatException {
  const ChatConnectionException(super.message);
}

class ChatProtocolException extends ChatException {
  const ChatProtocolException(super.message);
}

class ChatTimeoutException extends ChatException {
  const ChatTimeoutException(super.message);
}

class ChatStorageException extends ChatException {
  const ChatStorageException(super.message);
}
