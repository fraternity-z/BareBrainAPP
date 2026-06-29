import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;

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
    final isError = message.error != null;
    final isPendingAssistant =
        message.author == ChatMessageAuthor.assistant && message.isPending;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final style = _BubbleStyle.resolve(
      colors,
      isUser: isUser,
      isSystem: isSystem,
      isError: isError,
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
    final canShowRetry = !message.isPending &&
        onRetry != null &&
        displaySettings.showMessageActions;

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
                  if (isPendingAssistant)
                    _PendingAssistantContent(
                      foreground: style.foreground,
                      textStyle: contentStyle,
                    )
                  else
                    _MessageContent(
                      author: message.author,
                      content: message.content,
                      foreground: style.foreground,
                      textStyle: contentStyle,
                      selectable: displaySettings.selectableMessageText,
                      foldThinkingSteps: displaySettings.foldThinkingSteps,
                      inlineMathRendering: displaySettings.inlineMathRendering,
                      mathEquationRendering:
                          displaySettings.mathEquationRendering,
                      userMarkdownRendering:
                          displaySettings.userMessageMarkdownRendering,
                      reasoningMarkdownRendering:
                          displaySettings.reasoningMarkdownRendering,
                      assistantMarkdownRendering:
                          displaySettings.assistantMessageMarkdownRendering,
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

class _PendingAssistantContent extends StatefulWidget {
  const _PendingAssistantContent({
    required this.foreground,
    required this.textStyle,
  });

  final Color foreground;
  final TextStyle? textStyle;

  @override
  State<_PendingAssistantContent> createState() =>
      _PendingAssistantContentState();
}

class _PendingAssistantContentState extends State<_PendingAssistantContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle?.copyWith(
          color: widget.foreground,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          color: widget.foreground,
          fontWeight: FontWeight.w700,
        );

    return Semantics(
      label: 'BareBrain 正在思考',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('正在思考', style: style),
            const SizedBox(width: 7),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(3, (index) {
                    final phase = (_controller.value + index / 3) % 1;
                    final opacity =
                        phase < 0.5 ? 0.35 + phase * 1.3 : 1.65 - phase * 1.3;
                    final scale =
                        phase < 0.5 ? 0.82 + phase * 0.36 : 1.18 - phase * 0.36;

                    return Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.foreground,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: 5),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.author,
    required this.content,
    required this.foreground,
    required this.textStyle,
    required this.selectable,
    required this.foldThinkingSteps,
    required this.inlineMathRendering,
    required this.mathEquationRendering,
    required this.userMarkdownRendering,
    required this.reasoningMarkdownRendering,
    required this.assistantMarkdownRendering,
  });

  final ChatMessageAuthor author;
  final String content;
  final Color foreground;
  final TextStyle? textStyle;
  final bool selectable;
  final bool foldThinkingSteps;
  final bool inlineMathRendering;
  final bool mathEquationRendering;
  final bool userMarkdownRendering;
  final bool reasoningMarkdownRendering;
  final bool assistantMarkdownRendering;

  @override
  Widget build(BuildContext context) {
    final markdownOptions = _MarkdownRenderOptions(
      inlineMath: inlineMathRendering,
      blockMath: mathEquationRendering,
    );
    final messageMarkdown = _markdownEnabledFor(author);

    if (!foldThinkingSteps) {
      return _MessageTextRenderer(
        content: content,
        selectable: selectable,
        style: textStyle,
        foreground: foreground,
        markdown: messageMarkdown,
        markdownOptions: markdownOptions,
      );
    }

    final segments = _parseThinkingSegments(content);
    if (segments.length == 1 && !segments.first.isThinking) {
      return _MessageTextRenderer(
        content: content,
        selectable: selectable,
        style: textStyle,
        foreground: foreground,
        markdown: messageMarkdown,
        markdownOptions: markdownOptions,
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
                markdown: reasoningMarkdownRendering,
                markdownOptions: markdownOptions,
              )
            : _MessageTextRenderer(
                content: text,
                selectable: selectable,
                style: textStyle,
                foreground: foreground,
                markdown: messageMarkdown,
                markdownOptions: markdownOptions,
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

  bool _markdownEnabledFor(ChatMessageAuthor author) {
    return switch (author) {
      ChatMessageAuthor.user => userMarkdownRendering,
      ChatMessageAuthor.assistant => assistantMarkdownRendering,
      ChatMessageAuthor.system => false,
    };
  }
}

class _MessageTextRenderer extends StatelessWidget {
  const _MessageTextRenderer({
    required this.content,
    required this.selectable,
    required this.style,
    required this.foreground,
    required this.markdown,
    required this.markdownOptions,
  });

  final String content;
  final bool selectable;
  final TextStyle? style;
  final Color foreground;
  final bool markdown;
  final _MarkdownRenderOptions markdownOptions;

  @override
  Widget build(BuildContext context) {
    if (markdown) {
      return _MarkdownMessageText(
        content: content,
        selectable: selectable,
        style: style,
        foreground: foreground,
        options: markdownOptions,
      );
    }

    if (selectable) {
      return SelectableText(content, style: style);
    }

    return Text(content, style: style);
  }
}

class _MarkdownMessageText extends StatelessWidget {
  const _MarkdownMessageText({
    required this.content,
    required this.selectable,
    required this.style,
    required this.foreground,
    required this.options,
  });

  final String content;
  final bool selectable;
  final TextStyle? style;
  final Color foreground;
  final _MarkdownRenderOptions options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium;
    final codeStyle = baseStyle?.copyWith(
      color: foreground,
      fontFamily: 'monospace',
      backgroundColor: foreground.withValues(alpha: 0.08),
    );
    final normalized = _normalizeMathBlocks(content, options);
    final syntaxes = <md.BlockSyntax>[
      if (options.blockMath) LatexBlockSyntax(),
      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    ];
    final inlineSyntaxes = <md.InlineSyntax>[
      if (options.inlineMath || options.blockMath) LatexInlineSyntax(),
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
    ];

    return MarkdownBody(
      data: normalized,
      selectable: selectable,
      softLineBreak: true,
      fitContent: true,
      builders: <String, MarkdownElementBuilder>{
        if (options.inlineMath || options.blockMath)
          'latex': LatexElementBuilder(
            textStyle: baseStyle?.copyWith(color: foreground),
          ),
      },
      extensionSet: md.ExtensionSet(syntaxes, inlineSyntaxes),
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle?.copyWith(color: foreground),
        h1: baseStyle?.copyWith(
          color: foreground,
          fontSize: (baseStyle.fontSize ?? 14) * 1.42,
          fontWeight: FontWeight.w800,
        ),
        h2: baseStyle?.copyWith(
          color: foreground,
          fontSize: (baseStyle.fontSize ?? 14) * 1.28,
          fontWeight: FontWeight.w800,
        ),
        h3: baseStyle?.copyWith(
          color: foreground,
          fontSize: (baseStyle.fontSize ?? 14) * 1.14,
          fontWeight: FontWeight.w800,
        ),
        h4: baseStyle?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        h5: baseStyle?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        h6: baseStyle?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        em: baseStyle?.copyWith(
          color: foreground,
          fontStyle: FontStyle.italic,
        ),
        strong: baseStyle?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        del: baseStyle?.copyWith(
          color: foreground,
          decoration: TextDecoration.lineThrough,
        ),
        blockquote: baseStyle?.copyWith(
          color: foreground.withValues(alpha: 0.86),
          fontStyle: FontStyle.italic,
        ),
        code: codeStyle,
        listBullet: baseStyle?.copyWith(color: foreground),
        tableHead: baseStyle?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
        tableBody: baseStyle?.copyWith(color: foreground),
        blockSpacing: 10,
        listIndent: 22,
        codeblockPadding: const EdgeInsets.all(10),
        codeblockDecoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: foreground.withValues(alpha: 0.12)),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        blockquoteDecoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: foreground.withValues(alpha: 0.34),
              width: 3,
            ),
          ),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: foreground.withValues(alpha: 0.22),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkdownRenderOptions {
  const _MarkdownRenderOptions({
    required this.inlineMath,
    required this.blockMath,
  });

  final bool inlineMath;
  final bool blockMath;
}

class _ThinkingBlock extends StatelessWidget {
  const _ThinkingBlock({
    required this.content,
    required this.foreground,
    required this.textStyle,
    required this.selectable,
    required this.markdown,
    required this.markdownOptions,
  });

  final String content;
  final Color foreground;
  final TextStyle? textStyle;
  final bool selectable;
  final bool markdown;
  final _MarkdownRenderOptions markdownOptions;

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
            _MessageTextRenderer(
              content: content,
              selectable: selectable,
              style: textStyle,
              foreground: foreground,
              markdown: markdown,
              markdownOptions: markdownOptions,
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

String _normalizeMathBlocks(String content, _MarkdownRenderOptions options) {
  var normalized = content;

  if (!options.blockMath) {
    normalized = normalized
        .replaceAllMapped(_displayParenBlockPattern, (match) {
          return '${match.group(1)}${match.group(2)}${match.group(3)}';
        })
        .replaceAllMapped(_displayDollarBlockPattern, (match) {
          return '${match.group(1)}${match.group(2)}${match.group(3)}';
        });
  }

  if (!options.inlineMath) {
    normalized = normalized.replaceAllMapped(_inlineParenPattern, (match) {
      return '${match.group(1)}${match.group(2)}${match.group(3)}';
    });
    normalized = normalized.replaceAllMapped(_inlineDollarPattern, (match) {
      return '${match.group(1)}${match.group(2)}${match.group(3)}';
    });
  }

  if (!options.blockMath) {
    return normalized;
  }

  return normalized
      .replaceAllMapped(_displayBracketMultilinePattern, (match) {
        final body = match.group(1)?.trim() ?? '';
        return '\\[ $body \\]';
      })
      .replaceAllMapped(_displayDollarMultilinePattern, (match) {
        final body = match.group(1)?.trim() ?? '';
        return '\$\$\n$body\n\$\$';
      });
}

final _displayBracketMultilinePattern = RegExp(
  r'\\\[\s*\r?\n([\s\S]*?)\r?\n\s*\\\]',
);
final _displayDollarMultilinePattern = RegExp(
  r'\$\$\s*\r?\n([\s\S]*?)\r?\n\s*\$\$',
);
final _displayParenBlockPattern = RegExp(
  r'(\\\[)([\s\S]*?)(\\\])',
);
final _displayDollarBlockPattern = RegExp(
  r'(\$\$)([\s\S]*?)(\$\$)',
);
final _inlineParenPattern = RegExp(
  r'(\\\()([^\n]*?)(\\\))',
);
final _inlineDollarPattern = RegExp(
  r'(?<!\$)(\$)([^\n$]+?)(\$)(?!\$)',
);

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
      child: ExcludeSemantics(
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
    required bool isError,
    required ChatMessageBackground background,
  }) {
    if (isSystem) {
      if (!isError) {
        return _BubbleStyle(
          background: colors.secondaryContainer,
          foreground: colors.onSecondaryContainer,
          border: colors.secondary,
          borderOpacity: 0.44,
          shadowAlpha: 0.04,
          intensity: LiquidGlassIntensity.subtle,
        );
      }

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
