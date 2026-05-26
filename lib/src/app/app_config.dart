import '../features/chat/domain/entities/chat_connection_settings.dart';

class AppConfig {
  const AppConfig._();

  static const defaultHost = String.fromEnvironment(
    'BAREBRAIN_HOST',
    defaultValue: '192.168.1.100',
  );

  static const defaultPort = int.fromEnvironment(
    'BAREBRAIN_PORT',
    defaultValue: 18789,
  );

  static const defaultClientId = String.fromEnvironment(
    'BAREBRAIN_CLIENT_ID',
    defaultValue: 'barebrain_app',
  );

  static ChatConnectionSettings defaultChatSettings() {
    return const ChatConnectionSettings(
      host: defaultHost,
      port: defaultPort,
      clientId: defaultClientId,
      responseTimeout: Duration(seconds: 90),
    );
  }
}
