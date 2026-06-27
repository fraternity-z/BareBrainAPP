import '../../../../core/errors/chat_exception.dart';
import '../entities/chat_connection_settings.dart';

class ChatConnectionSettingsParser {
  const ChatConnectionSettingsParser._();

  static const defaultPort = 18789;
  static const defaultRelayPath = '/ws/app';
  static const minTimeout = Duration(seconds: 5);
  static const maxTimeout = Duration(minutes: 5);

  static ChatConnectionSettings parse({
    required String hostInput,
    required String portInput,
    required String clientIdInput,
    required String timeoutSecondsInput,
    required bool secure,
    ChatConnectionMode mode = ChatConnectionMode.direct,
    String relayDeviceIdInput = '',
    String relayTokenInput = '',
    String relayPathInput = defaultRelayPath,
  }) {
    final endpoint = _parseEndpoint(hostInput, secure, mode);
    final port = _parsePort(portInput, endpoint.port, mode, endpoint.secure);
    final timeout = _parseTimeout(timeoutSecondsInput);
    final clientId = clientIdInput.trim();
    final relayDeviceId = relayDeviceIdInput.trim().isEmpty
        ? endpoint.queryParameters['device_id']?.trim() ?? ''
        : relayDeviceIdInput.trim();
    final relayToken = relayTokenInput.trim().isEmpty
        ? endpoint.queryParameters['token']?.trim() ?? ''
        : relayTokenInput.trim();
    final relayPath = _parseRelayPath(relayPathInput, endpoint.path, mode);

    final settings = ChatConnectionSettings(
      host: endpoint.host,
      port: port,
      clientId: clientId,
      responseTimeout: timeout,
      secure: endpoint.secure,
      mode: mode,
      relayDeviceId: relayDeviceId,
      relayToken: relayToken,
      relayPath: relayPath,
    );
    return normalize(settings);
  }

  static ChatConnectionSettings normalize(ChatConnectionSettings settings) {
    final normalized = settings.copyWith(
      host: settings.host.trim(),
      clientId: settings.clientId.trim(),
      relayDeviceId: settings.relayDeviceId.trim(),
      relayToken: settings.relayToken.trim(),
      relayPath: settings.relayPath.trim().isEmpty
          ? defaultRelayPath
          : settings.relayPath.trim(),
    );

    validate(normalized);
    return normalized;
  }

  static void validate(ChatConnectionSettings settings) {
    final host = settings.host.trim();
    final clientId = settings.clientId.trim();

    if (host.isEmpty) {
      throw const ChatValidationException('设备地址不能为空');
    }

    if (host.contains(RegExp(r'\s'))) {
      throw const ChatValidationException('设备地址不能包含空白字符');
    }

    if (host.contains('/') || host.contains(':')) {
      throw const ChatValidationException('设备地址只填写 IP 或主机名');
    }

    if (settings.port <= 0 || settings.port > 65535) {
      throw const ChatValidationException('端口必须在 1 到 65535 之间');
    }

    if (settings.isRelay) {
      _validateRelaySettings(settings);
    }

    if (clientId.isEmpty) {
      throw const ChatValidationException('客户端 ID 不能为空');
    }

    if (clientId.length > 31) {
      throw const ChatValidationException('客户端 ID 不能超过 31 个字符');
    }

    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(clientId)) {
      throw const ChatValidationException(
        '客户端 ID 只能包含字母、数字、下划线、点和短横线',
      );
    }

    if (settings.responseTimeout < minTimeout ||
        settings.responseTimeout > maxTimeout) {
      throw const ChatValidationException('超时秒数必须在 5 到 300 之间');
    }
  }

  static _Endpoint _parseEndpoint(
    String input,
    bool secure,
    ChatConnectionMode mode,
  ) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return _Endpoint(
        host: '',
        port: null,
        secure: secure,
        path: null,
        queryParameters: const <String, String>{},
      );
    }

    if (trimmed.contains('://') &&
        !trimmed.startsWith('ws://') &&
        !trimmed.startsWith('wss://')) {
      throw const ChatValidationException('设备地址只支持 ws:// 或 wss://');
    }

    final withScheme =
        trimmed.startsWith('ws://') || trimmed.startsWith('wss://')
            ? trimmed
            : '${secure ? 'wss' : 'ws'}://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      throw const ChatValidationException('设备地址格式不正确');
    }

    if ((uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      if (mode == ChatConnectionMode.direct || uri.hasFragment) {
        throw const ChatValidationException('设备地址只填写根地址');
      }
    }

    return _Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      secure: uri.scheme == 'wss',
      path: uri.path.isEmpty ? null : uri.path,
      queryParameters: uri.queryParameters,
    );
  }

  static int _parsePort(
    String input,
    int? endpointPort,
    ChatConnectionMode mode,
    bool secure,
  ) {
    if (endpointPort != null) {
      return endpointPort;
    }

    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      if (mode == ChatConnectionMode.relay) {
        return secure ? 443 : 80;
      }
      return defaultPort;
    }

    final port = int.tryParse(trimmed);
    if (port == null) {
      throw const ChatValidationException('端口必须是数字');
    }

    return port;
  }

  static Duration _parseTimeout(String input) {
    final seconds = int.tryParse(input.trim());
    if (seconds == null) {
      throw const ChatValidationException('超时秒数必须是数字');
    }

    return Duration(seconds: seconds);
  }

  static String _parseRelayPath(
    String input,
    String? endpointPath,
    ChatConnectionMode mode,
  ) {
    if (mode == ChatConnectionMode.direct) {
      return defaultRelayPath;
    }

    final trimmed = input.trim();
    final path = endpointPath != null &&
            endpointPath != '/' &&
            (trimmed.isEmpty || trimmed == defaultRelayPath)
        ? endpointPath
        : trimmed.isNotEmpty
            ? trimmed
            : defaultRelayPath;

    if (!path.startsWith('/')) {
      throw const ChatValidationException('Relay 路径必须以 / 开头');
    }

    if (path.contains(RegExp(r'\s')) ||
        path.contains('?') ||
        path.contains('#')) {
      throw const ChatValidationException('Relay 路径不能包含空白、查询或片段');
    }

    return path;
  }

  static void _validateRelaySettings(ChatConnectionSettings settings) {
    if (settings.relayDeviceId.isEmpty) {
      throw const ChatValidationException('Relay 设备 ID 不能为空');
    }

    if (settings.relayDeviceId.length > 64) {
      throw const ChatValidationException('Relay 设备 ID 不能超过 64 个字符');
    }

    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(settings.relayDeviceId)) {
      throw const ChatValidationException(
        'Relay 设备 ID 只能包含字母、数字、下划线、点和短横线',
      );
    }

    if (settings.relayToken.isEmpty) {
      throw const ChatValidationException('Relay Token 不能为空');
    }

    if (settings.relayToken.contains(RegExp(r'\s'))) {
      throw const ChatValidationException('Relay Token 不能包含空白字符');
    }

    if (settings.relayToken.length > 512) {
      throw const ChatValidationException('Relay Token 不能超过 512 个字符');
    }
  }
}

class _Endpoint {
  const _Endpoint({
    required this.host,
    required this.port,
    required this.secure,
    required this.path,
    required this.queryParameters,
  });

  final String host;
  final int? port;
  final bool secure;
  final String? path;
  final Map<String, String> queryParameters;
}
