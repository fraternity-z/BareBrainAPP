import '../entities/bare_brain_board_command.dart';

class BareBrainBoardCommandParser {
  const BareBrainBoardCommandParser._();

  static const List<String> supportedCommandNames = <String>[
    'set_wifi',
    'set_api_key',
    'set_model',
    'set_base_url',
    'set_model_provider',
    'set_memory_api_key',
    'set_memory_model',
    'set_memory_provider',
    'set_memory_base_url',
    'set_proxy',
    'clear_proxy',
    'set_search_key',
    'set_tavily_key',
    'config_show',
    'brn_help',
  ];

  static const Set<String> _unsupportedCommandNames = <String>{
    'wifi_status',
    'wifi_scan',
    'storage_status',
    'session_list',
    'session_clear',
    'heap_info',
    'skill_list',
    'skill_show',
    'skill_search',
    'tool_exec',
    'web_search',
    'heartbeat_trigger',
    'cron_start',
    'restart',
    'config_reset',
  };

  static BareBrainBoardCommand? parse(String source) {
    final normalized = _normalizeSource(source);
    if (normalized.isEmpty) {
      return null;
    }

    final commandName = _firstToken(normalized).toLowerCase();
    final isCommand = supportedCommandNames.contains(commandName) ||
        _unsupportedCommandNames.contains(commandName) ||
        commandName.startsWith('set_') ||
        commandName.startsWith('clear_');
    if (!isCommand) {
      return null;
    }

    final tokenized = _tokenize(normalized);
    if (tokenized.errorMessage != null) {
      return BareBrainBoardCommand.unsupported(
        source: source,
        message: tokenized.errorMessage!,
      );
    }

    final tokens = tokenized.tokens;
    if (tokens.isEmpty) {
      return null;
    }

    final command = tokens.first.toLowerCase();
    final args = tokens.skip(1).toList(growable: false);
    return switch (command) {
      'set_wifi' => _parseExact(
          source,
          args,
          2,
          () => BareBrainBoardCommand.save(
            source: source,
            patch: <String, String>{
              'ssid': args[0],
              'password': args[1],
            },
            summary: const <String>['WiFi SSID', 'WiFi 密码'],
          ),
        ),
      'set_api_key' => _parseOne(
          source,
          args,
          'API Key',
          'api_key',
        ),
      'set_model' => _parseOne(
          source,
          args,
          '模型',
          'model',
        ),
      'set_base_url' => _parseOne(
          source,
          args,
          'Base URL',
          'base_url',
        ),
      'set_model_provider' => _parseProvider(
          source,
          args,
          label: '模型供应商',
          key: 'provider',
        ),
      'set_memory_api_key' => _parseOne(
          source,
          args,
          '记忆 API Key',
          'memory_api_key',
        ),
      'set_memory_model' => _parseOne(
          source,
          args,
          '记忆模型',
          'memory_model',
        ),
      'set_memory_provider' => _parseProvider(
          source,
          args,
          label: '记忆模型供应商',
          key: 'memory_provider',
        ),
      'set_memory_base_url' => _parseOne(
          source,
          args,
          '记忆 Base URL',
          'memory_base_url',
        ),
      'set_proxy' => _parseProxy(source, args),
      'clear_proxy' => _parseExact(
          source,
          args,
          0,
          () => BareBrainBoardCommand.save(
            source: source,
            patch: const <String, String>{
              'proxy_host': '',
              'proxy_port': '',
              'proxy_type': '',
            },
            summary: const <String>['代理配置'],
          ),
        ),
      'set_search_key' => _parseOne(
          source,
          args,
          'Brave Search Key',
          'search_key',
        ),
      'set_tavily_key' => _parseOne(
          source,
          args,
          'Tavily Key',
          'tavily_key',
        ),
      'config_show' => _parseExact(
          source,
          args,
          0,
          () => BareBrainBoardCommand.showConfig(source: source),
        ),
      'brn_help' => _parseExact(
          source,
          args,
          0,
          () => BareBrainBoardCommand.help(source: source),
        ),
      _ when _unsupportedCommandNames.contains(command) =>
        BareBrainBoardCommand.unsupported(
          source: source,
          message: 'App 端暂不支持执行 $command；请在串口 CLI 中运行该命令。',
        ),
      _ => BareBrainBoardCommand.unsupported(
          source: source,
          message: '快捷列表暂不支持板子设置 $command。可打开“板子设置说明”查看支持项。',
        ),
    };
  }

  static BareBrainBoardCommand _parseOne(
    String source,
    List<String> args,
    String label,
    String key,
  ) {
    return _parseExact(
      source,
      args,
      1,
      () => BareBrainBoardCommand.save(
        source: source,
        patch: <String, String>{key: args[0]},
        summary: <String>[label],
      ),
    );
  }

  static BareBrainBoardCommand _parseProvider(
    String source,
    List<String> args, {
    required String label,
    required String key,
  }) {
    return _parseExact(source, args, 1, () {
      final provider = args[0].toLowerCase();
      if (provider != 'anthropic' && provider != 'openai') {
        return BareBrainBoardCommand.unsupported(
          source: source,
          message: '$label 只能是 anthropic 或 openai。',
        );
      }

      return BareBrainBoardCommand.save(
        source: source,
        patch: <String, String>{key: provider},
        summary: <String>[label],
      );
    });
  }

  static BareBrainBoardCommand _parseProxy(String source, List<String> args) {
    final proxyArgs = args.length == 2 ? <String>[...args, 'http'] : args;
    return _parseExact(source, proxyArgs, 3, () {
      final port = int.tryParse(proxyArgs[1]);
      if (port == null || port <= 0 || port > 65535) {
        return BareBrainBoardCommand.unsupported(
          source: source,
          message: '代理端口必须在 1 到 65535 之间。',
        );
      }

      final type = proxyArgs[2].toLowerCase();
      if (type != 'http' && type != 'socks5') {
        return BareBrainBoardCommand.unsupported(
          source: source,
          message: '代理类型只能是 http 或 socks5。',
        );
      }

      return BareBrainBoardCommand.save(
        source: source,
        patch: <String, String>{
          'proxy_host': proxyArgs[0],
          'proxy_port': proxyArgs[1],
          'proxy_type': type,
        },
        summary: const <String>['代理地址', '代理端口', '代理类型'],
      );
    }, alternativeArgCount: 2);
  }

  static BareBrainBoardCommand _parseExact(
    String source,
    List<String> args,
    int count,
    BareBrainBoardCommand Function() build, {
    int? alternativeArgCount,
  }) {
    if (args.length != count) {
      final expected = alternativeArgCount == null
          ? '$count'
          : '$alternativeArgCount 或 $count';
      return BareBrainBoardCommand.unsupported(
        source: source,
        message: '指令参数数量不正确，需要 $expected 个参数。',
      );
    }

    if (args.any((arg) => arg.trim().isEmpty)) {
      return BareBrainBoardCommand.unsupported(
        source: source,
        message: '指令参数不能为空。',
      );
    }

    return build();
  }

  static String _normalizeSource(String source) {
    var value = source.trim();
    if (value.startsWith('brn>')) {
      value = value.substring(4).trimLeft();
    }
    if (value.startsWith('/')) {
      value = value.substring(1).trimLeft();
    }
    return value;
  }

  static String _firstToken(String source) {
    final match = RegExp(r'^\S+').firstMatch(source);
    return match?.group(0) ?? '';
  }

  static _TokenizedBoardCommand _tokenize(String source) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    String? quote;
    var escaping = false;

    void flush() {
      if (buffer.isEmpty) {
        return;
      }
      tokens.add(buffer.toString());
      buffer.clear();
    }

    for (var index = 0; index < source.length; index++) {
      final char = source[index];
      if (escaping) {
        buffer.write(char);
        escaping = false;
        continue;
      }

      if (char == '\\') {
        escaping = true;
        continue;
      }

      if (quote != null) {
        if (char == quote) {
          quote = null;
        } else {
          buffer.write(char);
        }
        continue;
      }

      if (char == '"' || char == "'") {
        quote = char;
        continue;
      }

      if (char.trim().isEmpty) {
        flush();
        continue;
      }

      buffer.write(char);
    }

    if (escaping) {
      buffer.write('\\');
    }
    if (quote != null) {
      return const _TokenizedBoardCommand(
        tokens: <String>[],
        errorMessage: '指令引号未闭合。',
      );
    }
    flush();
    return _TokenizedBoardCommand(tokens: tokens);
  }
}

class _TokenizedBoardCommand {
  const _TokenizedBoardCommand({
    required this.tokens,
    this.errorMessage,
  });

  final List<String> tokens;
  final String? errorMessage;
}
