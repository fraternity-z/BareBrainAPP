class BareBrainBoardCommand {
  const BareBrainBoardCommand._({
    required this.source,
    required this.action,
    this.patch = const <String, String>{},
    this.summary = const <String>[],
    this.errorMessage,
  });

  factory BareBrainBoardCommand.save({
    required String source,
    required Map<String, String> patch,
    required List<String> summary,
  }) {
    return BareBrainBoardCommand._(
      source: source,
      action: BareBrainBoardCommandAction.saveConfig,
      patch: Map<String, String>.unmodifiable(patch),
      summary: List<String>.unmodifiable(summary),
    );
  }

  factory BareBrainBoardCommand.showConfig({required String source}) {
    return BareBrainBoardCommand._(
      source: source,
      action: BareBrainBoardCommandAction.showConfig,
    );
  }

  factory BareBrainBoardCommand.help({required String source}) {
    return BareBrainBoardCommand._(
      source: source,
      action: BareBrainBoardCommandAction.help,
    );
  }

  factory BareBrainBoardCommand.unsupported({
    required String source,
    required String message,
  }) {
    return BareBrainBoardCommand._(
      source: source,
      action: BareBrainBoardCommandAction.unsupported,
      errorMessage: message,
    );
  }

  final String source;
  final BareBrainBoardCommandAction action;
  final Map<String, String> patch;
  final List<String> summary;
  final String? errorMessage;
}

enum BareBrainBoardCommandAction {
  saveConfig,
  showConfig,
  help,
  unsupported,
}

class BareBrainBoardCommandResult {
  const BareBrainBoardCommandResult({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;
}
