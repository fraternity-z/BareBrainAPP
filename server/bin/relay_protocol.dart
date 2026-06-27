import 'dart:convert';

class RelayProtocolException implements Exception {
  const RelayProtocolException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, Object?> decodeObject(Object? data) {
  if (data is! String) {
    throw const RelayProtocolException('Only text WebSocket frames are supported');
  }

  final decoded = jsonDecode(data);
  if (decoded is! Map<String, Object?>) {
    throw const RelayProtocolException('Payload must be a JSON object');
  }

  return decoded;
}

String encodeObject(Map<String, Object?> value) {
  return jsonEncode(value);
}

String requiredString(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! String || field.trim().isEmpty) {
    throw RelayProtocolException('Missing required field: $key');
  }

  return field;
}

String optionalRequestId(Map<String, Object?> value) {
  final field = value['request_id'];
  if (field is String && field.trim().isNotEmpty) {
    return field;
  }

  return DateTime.now().microsecondsSinceEpoch.toString();
}

Map<String, Object?> errorPayload({
  required String requestId,
  required String message,
  String? chatId,
}) {
  return <String, Object?>{
    'type': 'error',
    'request_id': requestId,
    if (chatId != null) 'chat_id': chatId,
    'message': message,
  };
}
