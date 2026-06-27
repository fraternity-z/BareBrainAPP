import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_ota_settings.dart';
import '../../domain/services/chat_connection_settings_parser.dart';
import '../../domain/services/chat_ota_settings_parser.dart';

class ChatConnectionSettingsCodec {
  const ChatConnectionSettingsCodec._();

  static Map<String, dynamic> toJson(ChatConnectionSettings settings) {
    return <String, dynamic>{
      'host': settings.host,
      'port': settings.port,
      'clientId': settings.clientId,
      'responseTimeoutMs': settings.responseTimeout.inMilliseconds,
      'secure': settings.secure,
      'mode': settings.mode.name,
      'relayDeviceId': settings.relayDeviceId,
      'relayToken': settings.relayToken,
      'relayPath': settings.relayPath,
      'otaSettings': ChatOtaSettingsCodec.toJson(settings.otaSettings),
    };
  }

  static ChatConnectionSettings fromJson(Map<String, dynamic> value) {
    final host = value['host'];
    final port = value['port'];
    final clientId = value['clientId'];
    final responseTimeoutMs = value['responseTimeoutMs'];
    final secure = value['secure'];
    final mode = value['mode'];
    final relayDeviceId = value['relayDeviceId'];
    final relayToken = value['relayToken'];
    final relayPath = value['relayPath'];
    final otaSettings = value['otaSettings'];

    if (host is! String ||
        port is! int ||
        clientId is! String ||
        responseTimeoutMs is! int) {
      throw const ChatStorageException('会话连接设置格式错误');
    }

    return ChatConnectionSettingsParser.normalize(
      ChatConnectionSettings(
        host: host,
        port: port,
        clientId: clientId,
        responseTimeout: Duration(milliseconds: responseTimeoutMs),
        secure: secure is bool ? secure : false,
        mode: _modeFromJson(mode),
        relayDeviceId: relayDeviceId is String ? relayDeviceId : '',
        relayToken: relayToken is String ? relayToken : '',
        relayPath: relayPath is String
            ? relayPath
            : ChatConnectionSettingsParser.defaultRelayPath,
        otaSettings: otaSettings is Map<String, dynamic>
            ? ChatOtaSettingsCodec.fromJson(otaSettings)
            : const ChatOtaSettings(),
      ),
    );
  }

  static ChatConnectionMode _modeFromJson(Object? value) {
    if (value is String) {
      for (final mode in ChatConnectionMode.values) {
        if (mode.name == value) {
          return mode;
        }
      }
    }

    return ChatConnectionMode.direct;
  }
}

class ChatOtaSettingsCodec {
  const ChatOtaSettingsCodec._();

  static Map<String, dynamic> toJson(ChatOtaSettings settings) {
    return <String, dynamic>{
      'versionPath': settings.versionPath,
      'firmwarePath': settings.firmwarePath,
      'channel': settings.channel,
      'requestTimeoutMs': settings.requestTimeout.inMilliseconds,
      'autoCheck': settings.autoCheck,
    };
  }

  static ChatOtaSettings fromJson(
    Map<String, dynamic> value, {
    ChatOtaSettings fallback = const ChatOtaSettings(),
  }) {
    final versionPath = value['versionPath'];
    final firmwarePath = value['firmwarePath'];
    final channel = value['channel'];
    final requestTimeoutMs = value['requestTimeoutMs'];
    final autoCheck = value['autoCheck'];

    return ChatOtaSettingsParser.normalize(
      fallback.copyWith(
        versionPath: versionPath is String ? versionPath : fallback.versionPath,
        firmwarePath:
            firmwarePath is String ? firmwarePath : fallback.firmwarePath,
        channel: channel is String ? channel : fallback.channel,
        requestTimeout: requestTimeoutMs is int
            ? Duration(milliseconds: requestTimeoutMs)
            : fallback.requestTimeout,
        autoCheck: autoCheck is bool ? autoCheck : fallback.autoCheck,
      ),
    );
  }
}
