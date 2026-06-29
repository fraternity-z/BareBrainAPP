import '../entities/bare_brain_board_command.dart';
import '../entities/chat_connection_settings.dart';
import '../repositories/bare_brain_board_config_client.dart';
import '../services/bare_brain_board_command_parser.dart';

class RunBareBrainBoardCommand {
  const RunBareBrainBoardCommand(this._client);

  final BareBrainBoardConfigClient _client;

  Future<BareBrainBoardCommandResult?> call(
    String source,
    ChatConnectionSettings settings,
  ) async {
    final command = BareBrainBoardCommandParser.parse(source);
    if (command == null) {
      return null;
    }

    return switch (command.action) {
      BareBrainBoardCommandAction.saveConfig => _save(command, settings),
      BareBrainBoardCommandAction.showConfig => _showConfig(settings),
      BareBrainBoardCommandAction.help => Future.value(_help()),
      BareBrainBoardCommandAction.unsupported => Future.value(
          BareBrainBoardCommandResult(
            message: command.errorMessage ?? '不支持的板子指令',
            isError: true,
          ),
        ),
    };
  }

  Future<BareBrainBoardCommandResult> _save(
    BareBrainBoardCommand command,
    ChatConnectionSettings settings,
  ) async {
    await _client.saveConfig(settings, command.patch);
    final changed = command.summary.join('、');
    return BareBrainBoardCommandResult(
      message: '已写入板子配置：$changed。\n设备会在保存后自动重启，稍后可重新连接。',
    );
  }

  Future<BareBrainBoardCommandResult> _showConfig(
    ChatConnectionSettings settings,
  ) async {
    final config = await _client.fetchConfig(settings);
    return BareBrainBoardCommandResult(
      message: _formatConfig(config),
    );
  }

  BareBrainBoardCommandResult _help() {
    return const BareBrainBoardCommandResult(
      message: '快捷列表支持的板子设置说明：\n'
          '查看板子配置：读取 BareBrain admin portal 当前配置。\n'
          '设置 WiFi：写入 WiFi SSID 和密码，保存后设备会重启。\n'
          '设置 API Key：写入主聊天模型使用的 API Key。\n'
          '设置模型：写入主聊天模型名称。\n'
          '设置模型供应商：在 Anthropic 和 OpenAI 之间切换。\n'
          '设置 Base URL：写入主聊天模型请求地址。\n'
          '设置记忆 API Key、模型、供应商和 Base URL：配置记忆模型服务。\n'
          '设置代理 / 清除代理：配置板子访问模型服务时使用的代理。\n'
          '设置 Brave Search Key / Tavily Key：配置搜索服务 Key。\n\n'
          '这些操作从聊天框左下角的快捷列表进入，不会发送给聊天模型。',
    );
  }

  String _formatConfig(Map<String, String> config) {
    const rows = <_ConfigRow>[
      _ConfigRow('ssid', 'WiFi SSID'),
      _ConfigRow('password', 'WiFi 密码', secret: true),
      _ConfigRow('api_key', 'API Key', secret: true),
      _ConfigRow('model', '模型'),
      _ConfigRow('provider', '供应商'),
      _ConfigRow('base_url', 'Base URL'),
      _ConfigRow('memory_api_key', '记忆 API Key', secret: true),
      _ConfigRow('memory_model', '记忆模型'),
      _ConfigRow('memory_provider', '记忆供应商'),
      _ConfigRow('memory_base_url', '记忆 Base URL'),
      _ConfigRow('proxy_host', '代理地址'),
      _ConfigRow('proxy_port', '代理端口'),
      _ConfigRow('proxy_type', '代理类型'),
      _ConfigRow('search_key', 'Brave Search Key', secret: true),
      _ConfigRow('tavily_key', 'Tavily Key', secret: true),
    ];

    final lines = <String>['当前板子配置：'];
    for (final row in rows) {
      final value = config[row.key]?.trim() ?? '';
      lines.add('${row.label}: ${row.secret ? _mask(value) : _display(value)}');
    }
    return lines.join('\n');
  }

  String _display(String value) {
    return value.isEmpty ? '(空)' : value;
  }

  String _mask(String value) {
    if (value.isEmpty) {
      return '(空)';
    }

    if (value.length <= 6) {
      return '****';
    }

    return '${value.substring(0, 4)}****';
  }
}

class _ConfigRow {
  const _ConfigRow(
    this.key,
    this.label, {
    this.secret = false,
  });

  final String key;
  final String label;
  final bool secret;
}
