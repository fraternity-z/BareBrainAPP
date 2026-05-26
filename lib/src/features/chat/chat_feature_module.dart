import 'data/datasources/bare_brain_websocket_transport.dart';
import 'data/datasources/chat_transport.dart';
import 'data/datasources/key_value_store.dart';
import 'data/datasources/shared_preferences_key_value_store.dart';
import 'data/repositories/bare_brain_chat_repository.dart';
import 'data/repositories/key_value_chat_display_settings_store.dart';
import 'data/repositories/key_value_chat_conversation_catalog_store.dart';
import 'data/repositories/key_value_chat_session_store.dart';
import 'domain/entities/chat_connection_settings.dart';
import 'domain/usecases/check_chat_connection.dart';
import 'domain/usecases/send_chat_message.dart';
import 'presentation/controllers/chat_controller.dart';
import 'presentation/controllers/chat_display_settings_controller.dart';

class ChatFeatureModule {
  const ChatFeatureModule._();

  static ChatController createController({
    required ChatConnectionSettings initialSettings,
    ChatTransport? transport,
    KeyValueStore? keyValueStore,
  }) {
    final resolvedTransport = transport ?? BareBrainWebSocketTransport();
    final repository = BareBrainChatRepository(transport: resolvedTransport);
    final resolvedKeyValueStore =
        keyValueStore ?? SharedPreferencesKeyValueStore();

    return ChatController(
      checkConnection: CheckChatConnection(repository),
      sendChatMessage: SendChatMessage(repository),
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
}
