import 'package:flutter/material.dart';

import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_message.dart';
import '../formatters/chat_message_time_formatter.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.displaySettings = const ChatDisplaySettings(),
    this.onCopy,
    this.onRetry,
    super.key,
  });

  final ChatMessage message;
  final ChatDisplaySettings displaySettings;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.author == ChatMessageAuthor.user;
    final isSystem = message.author == ChatMessageAuthor.system;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final style = _BubbleStyle.resolve(
      colors,
      isUser: isUser,
      isSystem: isSystem,
      background: displaySettings.messageBackground,
    );
    final contentStyle = _scaledTextStyle(
      Theme.of(context).textTheme.bodyMedium,
      displaySettings.messageFontScale,
    )?.copyWith(
      color: style.foreground,
      fontFamily: _codeFontFamily(message.content, displaySettings),
      height: 1.42,
    );
    final canShowCopy = onCopy != null && displaySettings.showMessageActions;
    final canShowRetry = onRetry != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth < 840 ? constraints.maxWidth * 0.86 : 720.0;
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.gradient == null ? style.background : null,
                gradient: style.gradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 22 : 10),
                  topRight: Radius.circular(isUser ? 10 : 22),
                  bottomLeft: const Radius.circular(22),
                  bottomRight: const Radius.circular(22),
                ),
                border: Border.all(color: style.border, width: 0.7),
                boxShadow: style.shadows,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: displaySettings.compactMessageSpacing ? 12 : 15,
                  vertical: displaySettings.compactMessageSpacing ? 8 : 11,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    if (displaySettings.selectableMessageText)
                      SelectableText(
                        message.content,
                        style: contentStyle,
                      )
                    else
                      Text(
                        message.content,
                        style: contentStyle,
                      ),
                    if (displaySettings.showMessageTimestamps) ...<Widget>[
                      SizedBox(
                        height: displaySettings.compactMessageSpacing ? 4 : 6,
                      ),
                      Text(
                        ChatMessageTimeFormatter.format(message.createdAt),
                        style: _scaledTextStyle(
                          Theme.of(context).textTheme.labelSmall,
                          displaySettings.messageFontScale,
                        )?.copyWith(
                          color: style.foreground.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (message.isPending) ...<Widget>[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: style.foreground,
                        ),
                      ),
                    ],
                    if (canShowCopy || canShowRetry) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (canShowCopy)
                            IconButton(
                              tooltip: '复制消息',
                              onPressed: onCopy,
                              color: style.foreground,
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              icon: const Icon(Icons.copy_all_outlined),
                            ),
                          if (canShowRetry)
                            TextButton.icon(
                              onPressed: onRetry,
                              style: TextButton.styleFrom(
                                foregroundColor: style.foreground,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BubbleStyle {
  const _BubbleStyle({
    required this.background,
    required this.foreground,
    required this.border,
    this.gradient,
    this.shadows,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;

  static _BubbleStyle resolve(
    ColorScheme colors, {
    required bool isUser,
    required bool isSystem,
    required ChatMessageBackground background,
  }) {
    final assistantShadows = <BoxShadow>[
      BoxShadow(
        color: colors.shadow.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

    if (isSystem) {
      return _BubbleStyle(
        background: colors.errorContainer,
        foreground: colors.onErrorContainer,
        border: colors.error,
      );
    }

    return switch (background) {
      ChatMessageBackground.standard => _BubbleStyle(
          background: isUser ? colors.primary : colors.surfaceContainerLowest,
          foreground: isUser ? colors.onPrimary : colors.onSurface,
          border: isUser
              ? colors.primary.withValues(alpha: 0.24)
              : colors.outlineVariant.withValues(alpha: 0.82),
          gradient: isUser
              ? LinearGradient(
                  colors: <Color>[
                    colors.primary,
                    Color.alphaBlend(
                      colors.secondary.withValues(alpha: 0.34),
                      colors.primary,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          shadows: isUser
              ? <BoxShadow>[
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : assistantShadows,
        ),
      ChatMessageBackground.soft => _BubbleStyle(
          background:
              isUser ? colors.secondaryContainer : colors.surfaceContainerHigh,
          foreground: isUser ? colors.onSecondaryContainer : colors.onSurface,
          border: isUser
              ? colors.secondary.withValues(alpha: 0.34)
              : colors.outlineVariant.withValues(alpha: 0.82),
          shadows: assistantShadows,
        ),
      ChatMessageBackground.plain => _BubbleStyle(
          background: colors.surfaceContainerLowest,
          foreground: colors.onSurface,
          border: isUser ? colors.primary : colors.outlineVariant,
        ),
    };
  }
}

TextStyle? _scaledTextStyle(TextStyle? source, double scale) {
  if (source == null) {
    return null;
  }

  return source.copyWith(fontSize: (source.fontSize ?? 14) * scale);
}

String? _codeFontFamily(String content, ChatDisplaySettings settings) {
  final fontFamily = settings.codeFont.fontFamily;
  if (fontFamily == null) {
    return null;
  }

  if (content.contains('```') ||
      content.split('\n').any((line) => line.startsWith('    '))) {
    return fontFamily;
  }

  return null;
}
