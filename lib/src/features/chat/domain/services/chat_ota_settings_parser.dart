import '../../../../core/errors/chat_exception.dart';
import '../entities/chat_ota_settings.dart';

class ChatOtaSettingsParser {
  const ChatOtaSettingsParser._();

  static const minTimeout = Duration(seconds: 10);
  static const maxTimeout = Duration(minutes: 10);

  static ChatOtaSettings parse({
    required String versionPathInput,
    required String firmwarePathInput,
    required String channelInput,
    required String timeoutSecondsInput,
    required bool autoCheck,
  }) {
    final seconds = int.tryParse(timeoutSecondsInput.trim());
    if (seconds == null) {
      throw const ChatValidationException('OTA 超时秒数必须是数字');
    }

    final settings = ChatOtaSettings(
      versionPath: versionPathInput.trim(),
      firmwarePath: firmwarePathInput.trim(),
      channel: channelInput.trim(),
      requestTimeout: Duration(seconds: seconds),
      autoCheck: autoCheck,
    );
    return normalize(settings);
  }

  static ChatOtaSettings normalize(ChatOtaSettings settings) {
    final normalized = settings.copyWith(
      versionPath: settings.versionPath.trim(),
      firmwarePath: settings.firmwarePath.trim(),
      channel: settings.channel.trim(),
    );

    validate(normalized);
    return normalized;
  }

  static void validate(ChatOtaSettings settings) {
    _validatePath(settings.versionPath, 'OTA 版本检查路径');
    _validatePath(settings.firmwarePath, 'OTA 固件路径');

    if (settings.channel.isEmpty) {
      throw const ChatValidationException('OTA 通道不能为空');
    }

    if (settings.channel.length > 24) {
      throw const ChatValidationException('OTA 通道不能超过 24 个字符');
    }

    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(settings.channel)) {
      throw const ChatValidationException(
        'OTA 通道只能包含字母、数字、下划线、点和短横线',
      );
    }

    if (settings.requestTimeout < minTimeout ||
        settings.requestTimeout > maxTimeout) {
      throw const ChatValidationException('OTA 超时秒数必须在 10 到 600 之间');
    }
  }

  static void _validatePath(String path, String label) {
    if (path.isEmpty) {
      throw ChatValidationException('$label不能为空');
    }

    if (!path.startsWith('/')) {
      throw ChatValidationException('$label必须以 / 开头');
    }

    if (path.contains(RegExp(r'\s'))) {
      throw ChatValidationException('$label不能包含空白字符');
    }

    final uri = Uri.tryParse(path);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ChatValidationException('$label必须是设备内的相对路径');
    }
  }
}
