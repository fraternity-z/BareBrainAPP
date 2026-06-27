import 'package:flutter/material.dart';

import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_message.dart';
import 'liquid_glass.dart';

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
    final canShowRetry = onRetry != null && displaySettings.showMessageActions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth < 840 ? constraints.maxWidth * 0.86 : 720.0;
        final showAvatar = displaySettings.showMessageAvatars && maxWidth >= 96;
        final bubbleMaxWidth = showAvatar ? maxWidth - 43 : maxWidth;
        final bubbleRadius = BorderRadius.only(
          topLeft: Radius.circular(isUser ? 22 : 10),
          topRight: Radius.circular(isUser ? 10 : 22),
          bottomLeft: const Radius.circular(22),
          bottomRight: const Radius.circular(22),
        );
        final bubble = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
          child: LiquidGlass(
            borderRadius: bubbleRadius,
            tint: style.background,
            borderColor: style.border,
            borderOpacity: style.borderOpacity,
            shadowAlpha: style.shadowAlpha,
            intensity: style.intensity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: displaySettings.compactMessageSpacing ? 12 : 15,
                vertical: displaySettings.compactMessageSpacing ? 8 : 11,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  if (displaySettings.showMessageAuthorNames) ...<Widget>[
                    Text(
                      _authorLabel(message.author),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: style.foreground.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(
                      height: displaySettings.compactMessageSpacing ? 4 : 6,
                    ),
                  ],
                  _MessageContent(
                    content: message.content,
                    foreground: style.foreground,
                    textStyle: contentStyle,
                    selectable: displaySettings.selectableMessageText,
                    foldThinkingSteps: displaySettings.foldThinkingSteps,
                  ),
                  if (canShowRetry) ...<Widget>[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment:
                          isUser ? WrapAlignment.end : WrapAlignment.start,
                      children: <Widget>[
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
        );
        final avatar = showAvatar
            ? _MessageAuthorAvatar(author: message.author)
            : const SizedBox.shrink();
        final children = isUser
            ? <Widget>[
                bubble,
                if (showAvatar) const SizedBox(width: 9),
                if (showAvatar) avatar,
              ]
            : <Widget>[
                if (showAvatar) avatar,
                if (showAvatar) const SizedBox(width: 9),
                bubble,
              ];

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.content,
    required this.foreground,
    required this.textStyle,
    required this.selectable,
    required this.foldThinkingSteps,
  });

  final String content;
  final Color foreground;
  final TextStyle? textStyle;
  final bool selectable;
  final bool foldThinkingSteps;

  @override
  Widget build(BuildContext context) {
    if (!foldThinkingSteps) {
      return _MessageText(
        content: content,
        selectable: selectable,
        style: textStyle,
      );
    }

    final segments = _parseThinkingSegments(content);
    if (segments.length == 1 && !segments.first.isThinking) {
      return _MessageText(
        content: content,
        selectable: selectable,
        style: textStyle,
      );
    }

    final children = <Widget>[];
    for (final segment in segments) {
      final text = segment.content.trim();
      if (text.isEmpty) {
        continue;
      }

      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 8));
      }

      children.add(
        segment.isThinking
            ? _ThinkingBlock(
                content: text,
                foreground: foreground,
                textStyle: textStyle,
                selectable: selectable,
              )
            : _MessageText(
                content: text,
                selectable: selectable,
                style: textStyle,
              ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.content,
    required this.selectable,
    required this.style,
  });

  final String content;
  final bool selectable;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (selectable) {
      return SelectableText(content, style: style);
    }

    return Text(content, style: style);
  }
}

class _ThinkingBlock extends StatelessWidget {
  const _ThinkingBlock({
    required this.content,
    required this.foreground,
    required this.textStyle,
    required this.selectable,
  });

  final String content;
  final Color foreground;
  final TextStyle? textStyle;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          collapsedIconColor: foreground.withValues(alpha: 0.78),
          iconColor: foreground,
          title: Row(
            children: <Widget>[
              Icon(
                Icons.psychology_outlined,
                size: 17,
                color: foreground.withValues(alpha: 0.78),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '思考步骤',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle?.copyWith(
                    color: foreground.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          children: <Widget>[
            _MessageText(
              content: content,
              selectable: selectable,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingSegment {
  const _ThinkingSegment({
    required this.content,
    required this.isThinking,
  });

  final String content;
  final bool isThinking;
}

List<_ThinkingSegment> _parseThinkingSegments(String content) {
  final pattern = RegExp(
    r'<think(?:ing)?>([\s\S]*?)</think(?:ing)?>',
    caseSensitive: false,
  );
  final matches = pattern.allMatches(content).toList(growable: false);
  if (matches.isEmpty) {
    return <_ThinkingSegment>[
      _ThinkingSegment(content: content, isThinking: false),
    ];
  }

  final segments = <_ThinkingSegment>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      segments.add(
        _ThinkingSegment(
          content: content.substring(cursor, match.start),
          isThinking: false,
        ),
      );
    }

    segments.add(
      _ThinkingSegment(
        content: match.group(1) ?? '',
        isThinking: true,
      ),
    );
    cursor = match.end;
  }

  if (cursor < content.length) {
    segments.add(
      _ThinkingSegment(
        content: content.substring(cursor),
        isThinking: false,
      ),
    );
  }

  return segments;
}

class _MessageAuthorAvatar extends StatelessWidget {
  const _MessageAuthorAvatar({
    required this.author,
  });

  final ChatMessageAuthor author;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = switch (author) {
      ChatMessageAuthor.user => colors.primary,
      ChatMessageAuthor.assistant => colors.secondaryContainer,
      ChatMessageAuthor.system => colors.errorContainer,
    };
    final foreground = switch (author) {
      ChatMessageAuthor.user => colors.onPrimary,
      ChatMessageAuthor.assistant => colors.onSecondaryContainer,
      ChatMessageAuthor.system => colors.onErrorContainer,
    };

    return Semantics(
      label: _authorLabel(author),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: Text(
              _avatarLabel(author),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

String _authorLabel(ChatMessageAuthor author) {
  return switch (author) {
    ChatMessageAuthor.user => '我',
    ChatMessageAuthor.assistant => 'BareBrain',
    ChatMessageAuthor.system => '系统',
  };
}

String _avatarLabel(ChatMessageAuthor author) {
  return switch (author) {
    ChatMessageAuthor.user => '我',
    ChatMessageAuthor.assistant => 'B',
    ChatMessageAuthor.system => '!',
  };
}

class _BubbleStyle {
  const _BubbleStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderOpacity,
    required this.shadowAlpha,
    required this.intensity,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final double borderOpacity;
  final double shadowAlpha;
  final LiquidGlassIntensity intensity;

  static _BubbleStyle resolve(
    ColorScheme colors, {
    required bool isUser,
    required bool isSystem,
    required ChatMessageBackground background,
  }) {
    if (isSystem) {
      return _BubbleStyle(
        background: colors.errorContainer,
        foreground: colors.onErrorContainer,
        border: colors.error,
        borderOpacity: 0.72,
        shadowAlpha: 0.04,
        intensity: LiquidGlassIntensity.subtle,
      );
    }

    return switch (background) {
      ChatMessageBackground.standard => _BubbleStyle(
          background: isUser ? colors.primary : colors.surfaceContainerLowest,
          foreground: isUser ? colors.onPrimary : colors.onSurface,
          border: isUser
              ? colors.primary.withValues(alpha: 0.24)
              : colors.outlineVariant.withValues(alpha: 0.82),
          borderOpacity: isUser ? 0.36 : 0.64,
          shadowAlpha: isUser ? 0.14 : 0.07,
          intensity: isUser
              ? LiquidGlassIntensity.prominent
              : LiquidGlassIntensity.balanced,
        ),
      ChatMessageBackground.soft => _BubbleStyle(
          background:
              isUser ? colors.secondaryContainer : colors.surfaceContainerHigh,
          foreground: isUser ? colors.onSecondaryContainer : colors.onSurface,
          border: isUser
              ? colors.secondary.withValues(alpha: 0.34)
              : colors.outlineVariant.withValues(alpha: 0.82),
          borderOpacity: isUser ? 0.48 : 0.58,
          shadowAlpha: 0.07,
          intensity: LiquidGlassIntensity.subtle,
        ),
      ChatMessageBackground.plain => _BubbleStyle(
          background: colors.surfaceContainerLowest,
          foreground: colors.onSurface,
          border: isUser ? colors.primary : colors.outlineVariant,
          borderOpacity: isUser ? 0.36 : 0.50,
          shadowAlpha: isUser ? 0.05 : 0.04,
          intensity: LiquidGlassIntensity.subtle,
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
