import 'data/datasources/bare_brain_websocket_transport.dart';
import 'data/datasources/bare_brain_board_admin_client.dart';
import 'data/datasources/chat_transport.dart';
import 'data/datasources/http_ota_version_checker.dart';
import 'data/datasources/key_value_store.dart';
import 'data/datasources/network_proxy_connection_tester.dart';
import 'data/datasources/shared_preferences_key_value_store.dart';
import 'data/repositories/bare_brain_chat_repository.dart';
import 'data/repositories/key_value_chat_app_settings_store.dart';
import 'data/repositories/key_value_chat_display_settings_store.dart';
import 'data/repositories/key_value_chat_conversation_catalog_store.dart';
import 'data/repositories/key_value_chat_session_store.dart';
import 'domain/entities/chat_app_settings.dart';
import 'domain/entities/chat_connection_settings.dart';
import 'domain/usecases/check_chat_connection.dart';
import 'domain/usecases/run_bare_brain_board_command.dart';
import 'domain/usecases/send_chat_message.dart';
import 'presentation/controllers/chat_app_settings_controller.dart';
import 'presentation/controllers/chat_controller.dart';
import 'presentation/controllers/chat_display_settings_controller.dart';

class ChatFeatureModule {
  const ChatFeatureModule._();

  static ChatController createController({
    required ChatConnectionSettings initialSettings,
    ChatTransport? transport,
    KeyValueStore? keyValueStore,
    ChatNetworkProxySettings Function()? networkProxySettingsProvider,
  }) {
    final resolvedTransport = transport ??
        BareBrainWebSocketTransport(
          networkProxySettingsProvider: networkProxySettingsProvider,
        );
    final repository = BareBrainChatRepository(transport: resolvedTransport);
    final resolvedKeyValueStore =
        keyValueStore ?? SharedPreferencesKeyValueStore();

    return ChatController(
      checkConnection: CheckChatConnection(repository),
      sendChatMessage: SendChatMessage(repository),
      runBoardCommand: RunBareBrainBoardCommand(
        BareBrainBoardAdminClient(
          networkProxySettingsProvider: networkProxySettingsProvider,
        ),
      ),
      initialSettings: initialSettings,
      sessionStoreFactory: KeyValueChatSessionStoreFactory(
        keyValueStore: resolvedKeyValueStore,
      ),
      catalogStore: KeyValueChatConversationCatalogStore(
        keyValueStore: resolvedKeyValueStore,
      ),
    );
  }

  static ChatDisplaySettingsController createDisplaySettingsController({
    KeyValueStore? keyValueStore,
  }) {
    final resolvedKeyValueStore =
        keyValueStore ?? SharedPreferencesKeyValueStore();

    return ChatDisplaySettingsController(
      store: KeyValueChatDisplaySettingsStore(
        keyValueStore: resolvedKeyValueStore,
      ),
    );
  }

  static ChatAppSettingsController createAppSettingsController({
    KeyValueStore? keyValueStore,
  }) {
    final resolvedKeyValueStore =
        keyValueStore ?? SharedPreferencesKeyValueStore();

    return ChatAppSettingsController(
      store: KeyValueChatAppSettingsStore(
        keyValueStore: resolvedKeyValueStore,
      ),
    );
  }

  static Future<void> testNetworkProxyConnection(
    ChatNetworkProxySettings settings,
  ) {
    return const NetworkProxyConnectionTester().test(settings);
  }

  static Future<void> testOtaVersionCheck(
    ChatConnectionSettings settings, {
    ChatNetworkProxySettings Function()? networkProxySettingsProvider,
  }) {
    return HttpOtaVersionChecker(
      networkProxySettingsProvider: networkProxySettingsProvider,
    ).check(settings);
  }
}
