import 'dart:io';

class ServerEnvironment {
  const ServerEnvironment._(this._values);

  static Future<ServerEnvironment> load() async {
    final values = <String, String>{
      ...Platform.environment,
    };

    final envFile = File('.env');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      for (final line in lines) {
        final parsed = _parseEnvLine(line);
        if (parsed != null) {
          values[parsed.key] = parsed.value;
        }
      }
    }

    return ServerEnvironment._(values);
  }

  final Map<String, String> _values;

  String string(String name, String fallback) {
    final value = _values[name];
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }

  int integer(String name, int fallback) {
    return int.tryParse(_values[name] ?? '') ?? fallback;
  }

  static _EnvEntry? _parseEnvLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      return null;
    }

    final separator = trimmed.indexOf('=');
    if (separator <= 0) {
      return null;
    }

    final key = trimmed.substring(0, separator).trim();
    final value = trimmed.substring(separator + 1).trim();
    if (key.isEmpty) {
      return null;
    }

    return _EnvEntry(key, _stripQuotes(value));
  }

  static String _stripQuotes(String value) {
    if (value.length < 2) {
      return value;
    }

    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }
}

class _EnvEntry {
  const _EnvEntry(this.key, this.value);

  final String key;
  final String value;
}
