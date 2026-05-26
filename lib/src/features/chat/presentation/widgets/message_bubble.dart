import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import '../formatters/chat_message_time_formatter.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.onCopy,
    this.onRetry,
    super.key,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.author == ChatMessageAuthor.user;
    final isSystem = message.author == ChatMessageAuthor.system;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final background = isUser
        ? colors.primary
        : isSystem
            ? colors.errorContainer
            : colors.surfaceContainerLowest;
    final foreground = isUser
        ? colors.onPrimary
        : isSystem
            ? colors.onErrorContainer
            : colors.onSurface;
    final borderColor = isUser
        ? colors.primary
        : isSystem
            ? colors.error
            : colors.outlineVariant;

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
                color: background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 0.7),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    SelectableText(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foreground,
                            height: 1.42,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ChatMessageTimeFormatter.format(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (message.isPending) ...<Widget>[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      ),
                    ],
                    if (onCopy != null || onRetry != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (onCopy != null)
                            IconButton(
                              tooltip: '复制消息',
                              onPressed: onCopy,
                              color: foreground,
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              icon: const Icon(Icons.copy_all_outlined),
                            ),
                          if (onRetry != null)
                            TextButton.icon(
                              onPressed: onRetry,
                              style: TextButton.styleFrom(
                                foregroundColor: foreground,
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
