import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/chat_conversation_summary.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/entities/chat_display_settings.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../controllers/chat_app_settings_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/chat_display_settings_controller.dart';
import '../settings/network_proxy_page.dart';
import '../settings/settings_page.dart';
import '../settings/voice_service_page.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.controller,
    this.displaySettings = const ChatDisplaySettings(),
    this.displaySettingsController,
    this.displaySettingsError,
    this.onDisplaySettingsChanged,
    this.appSettingsController,
    this.onTestNetworkProxyConnection,
    this.onTestVoiceService,
    this.onTestOtaVersionCheck,
    super.key,
  });

  final ChatController controller;
  final ChatDisplaySettings displaySettings;
  final ChatDisplaySettingsController? displaySettingsController;
  final String? displaySettingsError;
  final ValueChanged<ChatDisplaySettings>? onDisplaySettingsChanged;
  final ChatAppSettingsController? appSettingsController;
  final TestNetworkProxyConnection? onTestNetworkProxyConnection;
  final TestVoiceService? onTestVoiceService;
  final TestOtaVersionCheck? onTestOtaVersionCheck;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pendingAutoScrollTimer;
  String? _composerConversationId;
  bool _sidebarCollapsed = false;

  @override
  void dispose() {
    _pendingAutoScrollTimer?.cancel();
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _syncComposerForConversation();
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final desktopSidebarExpanded = wide && !_sidebarCollapsed;
            final drawerWidth = math.min(320.0, constraints.maxWidth * 0.8);
            return Scaffold(
              drawer: wide
                  ? null
                  : Drawer(
                      width: drawerWidth,
                      child: SafeArea(
                        child: _Sidebar(
                          controller: widget.controller,
                          onSettingsPressed: _openSettings,
                          closeAfterAction: true,
                          showBorder: false,
                          width: double.infinity,
                        ),
                      ),
                    ),
              body: SafeArea(
                child: LiquidGlassBackdrop(
                  key: const Key('chat_surface'),
                  baseColor: _chatSurfaceColor(
                    Theme.of(context).colorScheme,
                    widget.displaySettings,
                  ),
                  child: Row(
                    children: <Widget>[
                      _DesktopSidebarTransition(
                        expanded: desktopSidebarExpanded,
                        child: _Sidebar(
                          controller: widget.controller,
                          onSettingsPressed: _openSettings,
                        ),
                      ),
                      Expanded(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: desktopSidebarExpanded
                              ? (event) {
                                  if (_isSidebarTogglePointer(
                                    event.localPosition,
                                  )) {
                                    return;
                                  }
                                  setState(() {
                                    _sidebarCollapsed = true;
                                  });
                                }
                              : null,
                          child: Column(
                            children: <Widget>[
                              Builder(
                                builder: (scaffoldContext) {
                                  return _Header(
                                    settings: widget.controller.settings,
                                    sidebarExpanded:
                                        wide ? desktopSidebarExpanded : null,
                                    onSidebarPressed: wide
                                        ? () {
                                            setState(() {
                                              _sidebarCollapsed =
                                                  desktopSidebarExpanded;
                                            });
                                          }
                                        : null,
                                    onClearPressed: widget.controller.clear,
                                    onMenuPressed: wide
                                        ? null
                                        : () {
                                            Scaffold.of(scaffoldContext)
                                                .openDrawer();
                                          },
                                  );
                                },
                              ),
                              _StatusBanner(
                                controller: widget.controller,
                                onRetry: () => unawaited(_retryLastMessage()),
                              ),
                              Expanded(
                                child: _MessageList(
                                  controller: widget.controller,
                                  displaySettings: widget.displaySettings,
                                  onCopyMessage: (content) {
                                    unawaited(_copyMessage(content));
                                  },
                                  onRetryMessage: () {
                                    unawaited(_retryLastMessage());
                                  },
                                  scrollController: _scrollController,
                                ),
                              ),
                              _Composer(
                                controller: widget.controller,
                                displaySettings: widget.displaySettings,
                                textController: _composer,
                                onChanged: _updateDraft,
                                onSend: _send,
                                onShortcutCommandsPressed:
                                    _openShortcutCommandList,
                                onQuickPhrasesPressed:
                                    widget.appSettingsController == null
                                        ? null
                                        : _openQuickPhrasePicker,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _send() async {
    _syncRuntimeSettings();
    final text = _composer.text;
    _composer.clear();
    widget.controller.updateDraft('');
    if (widget.displaySettings.hapticFeedback && text.trim().isNotEmpty) {
      unawaited(HapticFeedback.selectionClick());
    }
    final appSettings = widget.appSettingsController?.settings;
    await widget.controller.send(
      text,
      transportContent: appSettings == null
          ? null
          : _buildTransportContent(text, appSettings),
    );
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom(widget.displaySettings.autoScrollDelay);
    });
  }

  Future<void> _retryLastMessage() async {
    _syncRuntimeSettings();
    final source = widget.controller.lastRetryableUserMessageContent;
    final appSettings = widget.appSettingsController?.settings;
    await widget.controller.retryLastUserMessage(
      transportContent: source == null || appSettings == null
          ? null
          : _buildTransportContent(source, appSettings),
    );
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleScrollToBottom(widget.displaySettings.autoScrollDelay);
    });
  }

  void _scheduleScrollToBottom(Duration delay) {
    _pendingAutoScrollTimer?.cancel();
    if (delay <= Duration.zero) {
      unawaited(_animateScrollToBottom());
      return;
    }

    _pendingAutoScrollTimer = Timer(delay, () {
      _pendingAutoScrollTimer = null;
      unawaited(_animateScrollToBottom());
    });
  }

  Future<void> _animateScrollToBottom() async {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  bool _isSidebarTogglePointer(Offset localPosition) {
    return localPosition.dy <= 92 && localPosition.dx <= 76;
  }

  void _syncComposerForConversation() {
    final conversationId = widget.controller.conversationId;
    final draft = widget.controller.draft;
    if (_composerConversationId == conversationId && _composer.text == draft) {
      return;
    }

    _composerConversationId = conversationId;
    _composer.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  void _updateDraft(String draft) {
    _syncRuntimeSettings();
    widget.controller.updateDraft(draft);
  }

  void _syncRuntimeSettings() {
    final settings = widget.appSettingsController?.settings;
    if (settings == null) {
      return;
    }

    widget.controller
      ..updateStorageSettings(settings.storage)
      ..updateVoiceSettings(settings.voice);
  }

  void _openSettings() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) {
            return ChatSettingsPage(
              settings: widget.controller.settings,
              onSettingsChanged: widget.controller.updateSettings,
              displaySettings: widget.displaySettings,
              displaySettingsController: widget.displaySettingsController,
              displaySettingsError: widget.displaySettingsError,
              onDisplaySettingsChanged: widget.onDisplaySettingsChanged,
              appSettingsController: widget.appSettingsController,
              onTestConnection: widget.controller.testConnection,
              onTestNetworkProxyConnection: widget.onTestNetworkProxyConnection,
              onTestVoiceService: widget.onTestVoiceService,
              onTestOtaVersionCheck: widget.onTestOtaVersionCheck,
              loadStorageUsage: widget.controller.loadStorageUsage,
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyMessage(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制')),
    );
  }

  Future<void> _openQuickPhrasePicker() async {
    final phrases = widget.appSettingsController?.settings.quickPhrases
            .where((phrase) => phrase.enabled)
            .toList(growable: false) ??
        const <ChatQuickPhrase>[];
    if (phrases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可用快捷短语')),
      );
      return;
    }

    final phrase = await showModalBottomSheet<ChatQuickPhrase>(
      context: context,
      showDragHandle: true,
      builder: (context) => _QuickPhrasePickerSheet(phrases: phrases),
    );

    if (phrase == null || !mounted) {
      return;
    }

    _insertComposerText(phrase.content);
  }

  Future<void> _openShortcutCommandList() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _ShortcutCommandListSheet(),
    );
  }

  void _insertComposerText(String content) {
    final selection = _composer.selection;
    final text = _composer.text;
    final insert = content.trim();
    if (insert.isEmpty) {
      return;
    }

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final separator =
        start > 0 && !text.substring(0, start).endsWith('\n') ? '\n' : '';
    final next = text.replaceRange(start, end, '$separator$insert');
    final offset = start + separator.length + insert.length;
    _composer.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
    );
    widget.controller.updateDraft(next);
  }

  String _buildTransportContent(String source, ChatAppSettings settings) {
    final normalized = source.trim();
    final prefix = <String>[];
    final suffix = <String>[];

    if (settings.worldBook.enabled) {
      final entries = _matchingWorldBookEntries(normalized, settings.worldBook);
      if (entries.isNotEmpty) {
        prefix.add(
          entries
              .map((entry) => '[世界书：${entry.title}]\n${entry.content}')
              .join('\n\n'),
        );
      }
    }

    if (settings.promptInjection.enabled) {
      for (final rule in settings.promptInjection.rules) {
        if (!rule.enabled || rule.content.trim().isEmpty) {
          continue;
        }

        switch (rule.position) {
          case ChatPromptInjectionPosition.systemPrefix:
            prefix.add('[系统指令：${rule.title}]\n${rule.content.trim()}');
            break;
          case ChatPromptInjectionPosition.userPrefix:
            prefix.add('[用户指令：${rule.title}]\n${rule.content.trim()}');
            break;
          case ChatPromptInjectionPosition.messageSuffix:
            suffix.add('[后置指令：${rule.title}]\n${rule.content.trim()}');
            break;
        }
      }
    }

    return <String>[
      ...prefix,
      normalized,
      ...suffix,
    ].where((part) => part.trim().isNotEmpty).join('\n\n');
  }

  List<ChatWorldBookEntry> _matchingWorldBookEntries(
    String source,
    ChatWorldBookSettings settings,
  ) {
    final lower = source.toLowerCase();
    final entries = <ChatWorldBookEntry>[];
    for (final entry in settings.entries) {
      if (!entry.enabled) {
        continue;
      }

      if (entry.keywords.isEmpty ||
          entry.keywords.any((keyword) {
            return lower.contains(keyword.toLowerCase());
          })) {
        entries.add(entry);
      }

      if (entries.length >= settings.maxActiveEntries) {
        break;
      }
    }

    return entries;
  }
}

TextStyle? _scaledTextStyle(TextStyle? source, double scale) {
  if (source == null) {
    return null;
  }

  return source.copyWith(fontSize: (source.fontSize ?? 14) * scale);
}

Color _chatSurfaceColor(
  ColorScheme colors,
  ChatDisplaySettings displaySettings,
) {
  final base = colors.surfaceContainerHigh.withValues(alpha: 0.32);
  return Color.alphaBlend(
    colors.surfaceContainerLow.withValues(
      alpha: displaySettings.backgroundMaskOpacity,
    ),
    base,
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.controller,
    required this.onRetry,
  });

  final ChatController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message =
        controller.isSending ? '正在等待 BareBrain 回复' : controller.errorMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    final isError = !controller.isSending;
    final background =
        isError ? colors.errorContainer : colors.secondaryContainer;
    final foreground =
        isError ? colors.onErrorContainer : colors.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isError ? colors.error : colors.outlineVariant,
            width: 0.7,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(
                isError ? Icons.error_outline : Icons.hourglass_empty,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (isError && controller.canRetryLastMessage) ...<Widget>[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(foregroundColor: foreground),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebarTransition extends StatelessWidget {
  const _DesktopSidebarTransition({
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const width = _Sidebar.expandedWidth;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: expanded ? width : 0,
        end: expanded ? width : 0,
      ),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, animatedWidth, child) {
        if (animatedWidth <= 0.5) {
          return const SizedBox(
            key: Key('desktop_sidebar_slot'),
            width: 0,
          );
        }

        return SizedBox(
          key: const Key('desktop_sidebar_slot'),
          width: animatedWidth,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: width,
              maxWidth: width,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.controller,
    required this.onSettingsPressed,
    this.closeAfterAction = false,
    this.showBorder = true,
    this.width,
  });

  static const double expandedWidth = 280;

  final ChatController controller;
  final VoidCallback onSettingsPressed;
  final bool closeAfterAction;
  final bool showBorder;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sidebarWidth = width ?? expandedWidth;
    return SizedBox(
      key: const Key('chat_sidebar'),
      width: sidebarWidth,
      child: LiquidGlass(
        borderRadius: BorderRadius.zero,
        tint: Color.alphaBlend(
          colors.primaryContainer.withValues(alpha: 0.16),
          colors.surfaceContainerLowest,
        ),
        borderColor: showBorder ? colors.outlineVariant : Colors.transparent,
        borderOpacity: showBorder ? 0.86 : 0,
        shadowAlpha: showBorder ? 0.08 : 0.12,
        intensity: LiquidGlassIntensity.subtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: _NewConversationButton(
                onPressed: () {
                  unawaited(controller.createConversation());
                  if (closeAfterAction) {
                    unawaited(Navigator.of(context).maybePop());
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.forum_outlined,
                    size: 17,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '会话',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ConversationList(
                controller: controller,
                closeAfterSelection: closeAfterAction,
              ),
            ),
            _SidebarFooter(
              onClearPressed: controller.clear,
              onSettingsPressed: () {
                if (closeAfterAction) {
                  unawaited(
                    Navigator.of(context).maybePop().then((_) {
                      onSettingsPressed();
                    }),
                  );
                  return;
                }

                onSettingsPressed();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BareBrainMark extends StatelessWidget {
  const _BareBrainMark({
    this.size = 48,
    this.label = '脑',
  });

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LiquidGlass(
      borderRadius: BorderRadius.circular(size / 2),
      tint: colors.primaryContainer,
      borderOpacity: 0.48,
      shadowAlpha: 0,
      intensity: LiquidGlassIntensity.subtle,
      child: SizedBox(
        height: size,
        width: size,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _NewConversationButton extends StatelessWidget {
  const _NewConversationButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: '新建会话',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 8,
            shadowColor: colors.primary.withValues(alpha: 0.22),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
          ),
          icon: const Icon(Icons.add_comment_outlined, size: 20),
          label: const Text(
            '新建会话',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.onClearPressed,
    required this.onSettingsPressed,
  });

  final VoidCallback onClearPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: LiquidGlass(
        borderRadius: BorderRadius.circular(24),
        tint: colors.surfaceContainerLowest,
        borderOpacity: 0.42,
        shadowAlpha: 0.08,
        intensity: LiquidGlassIntensity.subtle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          child: Row(
            children: <Widget>[
              const _BareBrainMark(size: 38, label: '用'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '用户',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: '清空会话',
                onPressed: onClearPressed,
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                tooltip: '设置',
                onPressed: onSettingsPressed,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = selected ? colors.primary : colors.surfaceContainerHigh;
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: SizedBox.square(
        dimension: 34,
        child: Icon(
          Icons.chat_bubble_outline,
          size: 17,
          color: foreground,
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.controller,
    required this.closeAfterSelection,
  });

  final ChatController controller;
  final bool closeAfterSelection;

  @override
  Widget build(BuildContext context) {
    final conversations = controller.conversations;
    if (conversations.isEmpty) {
      return Center(
        child: Text(
          '暂无会话',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationTile(
          conversation: conversation,
          selected: conversation.id == controller.conversationId,
          onRename: () => unawaited(
            _showRenameDialog(context, controller, conversation),
          ),
          onDelete: conversation.id == controller.conversationId
              ? null
              : () => unawaited(
                    controller.deleteConversation(conversation.id),
                  ),
          onTap: () {
            unawaited(controller.selectConversation(conversation.id));
            if (closeAfterSelection) {
              unawaited(Navigator.of(context).maybePop());
            }
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final ChatConversationSummary conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = conversation.lastMessagePreview.isEmpty
        ? conversation.settings.websocketUri.toString()
        : conversation.lastMessagePreview;
    final borderRadius = BorderRadius.circular(18);
    final tile = Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: ListTile(
        leading: _ConversationAvatar(selected: selected),
        selected: selected,
        selectedTileColor: Colors.transparent,
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? colors.primary : colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Text(
          preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: _ConversationMessageCount(count: conversation.messageCount),
        dense: true,
        minLeadingWidth: 34,
        horizontalTitleGap: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        onTap: selected ? null : onTap,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
        unawaited(_showActionsMenu(context, details.globalPosition));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: selected
            ? LiquidGlass(
                borderRadius: borderRadius,
                tint: colors.surfaceContainerLowest,
                borderColor: colors.primary,
                borderOpacity: 0.34,
                shadowAlpha: 0.07,
                intensity: LiquidGlassIntensity.subtle,
                child: tile,
              )
            : tile,
      ),
    );
  }

  Future<void> _showActionsMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) {
      return;
    }

    final colors = Theme.of(context).colorScheme;
    final anchor = globalPosition.translate(0, 8);
    final action = await showMenu<_ConversationMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(anchor, anchor),
        Offset.zero & overlay.size,
      ),
      color: colors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: colors.shadow.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(minWidth: 168),
      items: <PopupMenuEntry<_ConversationMenuAction>>[
        const PopupMenuItem<_ConversationMenuAction>(
          value: _ConversationMenuAction.rename,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: _ConversationMenuItem(
            icon: Icons.edit_outlined,
            label: '重命名',
          ),
        ),
        if (onDelete != null)
          const PopupMenuItem<_ConversationMenuAction>(
            value: _ConversationMenuAction.delete,
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _ConversationMenuItem(
              icon: Icons.delete_outline,
              label: '删除',
              destructive: true,
            ),
          ),
      ],
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _ConversationMenuAction.rename:
        onRename();
        break;
      case _ConversationMenuAction.delete:
        onDelete?.call();
        break;
    }
  }
}

enum _ConversationMenuAction { rename, delete }

class _ConversationMessageCount extends StatelessWidget {
  const _ConversationMessageCount({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        width: 30,
        height: 24,
        child: Center(
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _ConversationMenuItem extends StatelessWidget {
  const _ConversationMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = destructive ? colors.error : colors.onSurface;
    final iconForeground = destructive ? colors.error : colors.onSurfaceVariant;
    final iconBackground = destructive
        ? colors.errorContainer.withValues(alpha: 0.55)
        : colors.surfaceContainerHigh;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: SizedBox(
        width: 144,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 30,
                  child: Icon(icon, size: 17, color: iconForeground),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showRenameDialog(
  BuildContext context,
  ChatController controller,
  ChatConversationSummary conversation,
) async {
  final textController = TextEditingController(text: conversation.title);
  final nextTitle = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '会话标题',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
  textController.dispose();

  if (nextTitle == null) {
    return;
  }

  await controller.renameConversation(conversation.id, nextTitle);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.settings,
    required this.onClearPressed,
    this.sidebarExpanded,
    this.onSidebarPressed,
    this.onMenuPressed,
  });

  final ChatConnectionSettings settings;
  final VoidCallback onClearPressed;
  final bool? sidebarExpanded;
  final VoidCallback? onSidebarPressed;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sidebarAction = onSidebarPressed ?? onMenuPressed;
    final sidebarTooltip = onSidebarPressed == null
        ? '会话'
        : sidebarExpanded == true
            ? '折叠侧栏'
            : '展开侧栏';
    return SizedBox(
      height: 92,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: <Widget>[
            if (sidebarAction != null) ...<Widget>[
              IconButton(
                tooltip: sidebarTooltip,
                onPressed: sidebarAction,
                icon: Icon(
                  sidebarExpanded == true ? Icons.menu_open : Icons.menu,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '新对话',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 7),
                  _HeaderConnectionPill(
                    uri: settings.websocketUri.toString(),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '清空会话',
              onPressed: onClearPressed,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderConnectionPill extends StatelessWidget {
  const _HeaderConnectionPill({
    required this.uri,
  });

  final String uri;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: LiquidGlass(
        borderRadius: BorderRadius.circular(999),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        tint: colors.surfaceContainerLowest,
        borderOpacity: 0.56,
        shadowAlpha: 0,
        intensity: LiquidGlassIntensity.subtle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.wifi_tethering,
              size: 15,
              color: colors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                uri,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.displaySettings,
    required this.onCopyMessage,
    required this.onRetryMessage,
    required this.scrollController,
  });

  final ChatController controller;
  final ChatDisplaySettings displaySettings;
  final ValueChanged<String> onCopyMessage;
  final VoidCallback onRetryMessage;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (controller.messages.isEmpty) {
      return const _EmptyMessageView();
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      itemCount: controller.messages.length,
      separatorBuilder: (_, __) => SizedBox(
        height: displaySettings.compactMessageSpacing ? 8 : 14,
      ),
      itemBuilder: (context, index) {
        return MessageBubble(
          message: controller.messages[index],
          displaySettings: displaySettings,
          onCopy: () => onCopyMessage(controller.messages[index].content),
          onRetry: controller.canRetryLastMessage &&
                  index == controller.messages.length - 2
              ? onRetryMessage
              : null,
        );
      },
    );
  }
}

class _EmptyMessageView extends StatefulWidget {
  const _EmptyMessageView();

  @override
  State<_EmptyMessageView> createState() => _EmptyMessageViewState();
}

class _EmptyMessageViewState extends State<_EmptyMessageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '暂无消息，BareBrain 正在等你开口',
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 300.0;
                final width = math.max(0.0, math.min(300.0, maxWidth));

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RepaintBoundary(
                      child: SizedBox(
                        key: const Key('empty_message_animation'),
                        width: width,
                        height: width * 0.68,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _EmptyMessagePainter(
                                colors: colors,
                                progress: _controller.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '暂无消息',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BareBrain 正在等你开口',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessagePainter extends CustomPainter {
  const _EmptyMessagePainter({
    required this.colors,
    required this.progress,
  });

  static const Size _designSize = Size(300, 204);

  final ColorScheme colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _designSize.width,
      size.height / _designSize.height,
    );
    final dx = (size.width - _designSize.width * scale) / 2;
    final dy = (size.height - _designSize.height * scale) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final phase = progress * math.pi * 2;
    final bob = math.sin(phase) * 3.5;
    final line = _stroke(
      colors.onSurfaceVariant.withValues(alpha: 0.78),
      width: 2,
    );
    final softLine = _stroke(
      colors.onSurfaceVariant.withValues(alpha: 0.38),
      width: 1.4,
    );
    final fill = _fill(colors.surfaceContainerLowest);
    final softFill = _fill(colors.surfaceContainerHigh.withValues(alpha: 0.62));
    final accentFill = _fill(colors.secondary.withValues(alpha: 0.18));

    canvas.drawCircle(const Offset(116, 108), 68, softFill);
    canvas.drawCircle(
      Offset(216, 68 + math.sin(phase + 0.8) * 2),
      8,
      accentFill,
    );
    _drawBlinkingDots(canvas, phase);

    canvas.drawLine(const Offset(42, 169), const Offset(252, 169), softLine);
    canvas.drawLine(const Offset(62, 180), const Offset(224, 180), softLine);

    _drawSleepingBrain(canvas, line, softLine, fill, bob);
    _drawChatScreen(canvas, line, softLine, fill, bob);
    _drawFloatingZ(canvas);

    canvas.restore();
  }

  Paint _stroke(Color color, {required double width}) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Paint _fill(Color color) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  void _drawChatScreen(
    Canvas canvas,
    Paint line,
    Paint softLine,
    Paint fill,
    double bob,
  ) {
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(82, 78 + bob, 136, 76),
      const Radius.circular(9),
    );
    canvas
      ..drawRRect(screen, fill)
      ..drawRRect(screen, line);

    canvas.drawLine(
      Offset(122, 109 + bob),
      Offset(133, 120 + bob),
      line,
    );
    canvas.drawLine(
      Offset(133, 109 + bob),
      Offset(122, 120 + bob),
      line,
    );
    canvas.drawLine(
      Offset(166, 109 + bob),
      Offset(177, 120 + bob),
      line,
    );
    canvas.drawLine(
      Offset(177, 109 + bob),
      Offset(166, 120 + bob),
      line,
    );

    final tongue = Path()
      ..moveTo(146, 133 + bob)
      ..lineTo(146, 141 + bob)
      ..quadraticBezierTo(151, 145 + bob, 156, 141 + bob)
      ..lineTo(156, 133 + bob);
    canvas.drawPath(tongue, line);

    canvas.drawLine(
      Offset(138, 154 + bob),
      const Offset(138, 166),
      softLine,
    );
    canvas.drawLine(
      Offset(162, 154 + bob),
      const Offset(162, 166),
      softLine,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(118, 166, 64, 9),
        const Radius.circular(4.5),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(118, 166, 64, 9),
        const Radius.circular(4.5),
      ),
      softLine,
    );
  }

  void _drawSleepingBrain(
    Canvas canvas,
    Paint line,
    Paint softLine,
    Paint fill,
    double bob,
  ) {
    final y = bob;
    final cloud = Path()
      ..moveTo(77, 87 + y)
      ..cubicTo(61, 86 + y, 59, 65 + y, 75, 61 + y)
      ..cubicTo(78, 44 + y, 101, 42 + y, 108, 57 + y)
      ..cubicTo(122, 48 + y, 139, 59 + y, 137, 76 + y)
      ..cubicTo(137, 90 + y, 124, 95 + y, 113, 90 + y)
      ..cubicTo(103, 98 + y, 88, 98 + y, 77, 87 + y)
      ..close();

    canvas
      ..drawPath(cloud, fill)
      ..drawPath(cloud, line);
    canvas.drawArc(
      Rect.fromLTWH(83, 55 + y, 31, 34),
      math.pi * 0.12,
      math.pi * 0.65,
      false,
      softLine,
    );
    canvas.drawArc(
      Rect.fromLTWH(106, 58 + y, 25, 28),
      math.pi * 0.9,
      math.pi * 0.56,
      false,
      softLine,
    );

    canvas.drawLine(
      Offset(71, 102 + y),
      Offset(106, 102 + y),
      softLine,
    );
    canvas.drawLine(
      Offset(52, 114 + y),
      Offset(95, 114 + y),
      softLine,
    );
  }

  void _drawFloatingZ(Canvas canvas) {
    _paintZ(canvas, 'Z', const Offset(214, 26), 0.0, 16);
    _paintZ(canvas, 'z', const Offset(196, 48), 0.34, 13);
    _paintZ(canvas, 'z', const Offset(231, 8), 0.68, 12);
  }

  void _paintZ(
    Canvas canvas,
    String value,
    Offset base,
    double delay,
    double fontSize,
  ) {
    final local = (progress + delay) % 1;
    final alpha = math.sin(local * math.pi).clamp(0.0, 1.0).toDouble();
    final offset = base.translate(local * 10, -local * 17);
    final textPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: colors.onSurfaceVariant.withValues(alpha: 0.24 + alpha * 0.5),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  void _drawBlinkingDots(Canvas canvas, double phase) {
    final dotPaint = _fill(colors.onSurfaceVariant.withValues(alpha: 0.18));
    final pulsePaint = _fill(
      colors.onSurfaceVariant.withValues(
        alpha: 0.12 + (math.sin(phase) + 1) * 0.07,
      ),
    );

    canvas.drawCircle(const Offset(62, 70), 5, dotPaint);
    canvas.drawCircle(const Offset(238, 111), 3.5, dotPaint);
    canvas.drawCircle(const Offset(248, 126), 4, pulsePaint);
    canvas.drawCircle(const Offset(48, 92), 3, pulsePaint);

    final sparkle = _stroke(
      colors.onSurfaceVariant.withValues(alpha: 0.54),
      width: 1.8,
    );
    canvas.drawLine(const Offset(55, 39), const Offset(55, 51), sparkle);
    canvas.drawLine(const Offset(49, 45), const Offset(61, 45), sparkle);
    canvas.drawLine(const Offset(238, 45), const Offset(238, 56), sparkle);
    canvas.drawLine(const Offset(232, 50.5), const Offset(244, 50.5), sparkle);
  }

  @override
  bool shouldRepaint(covariant _EmptyMessagePainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.progress != progress;
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.displaySettings,
    required this.textController,
    required this.onChanged,
    required this.onSend,
    required this.onShortcutCommandsPressed,
    this.onQuickPhrasesPressed,
  });

  final ChatController controller;
  final ChatDisplaySettings displaySettings;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onShortcutCommandsPressed;
  final VoidCallback? onQuickPhrasesPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: LiquidGlass(
        key: const Key('chat_composer_surface'),
        borderRadius: BorderRadius.circular(32),
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
        tint: Color.alphaBlend(
          colors.primaryContainer.withValues(alpha: 0.08),
          colors.surfaceContainerLowest,
        ),
        borderOpacity: 0.42,
        shadowAlpha: 0.11,
        intensity: LiquidGlassIntensity.prominent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 42),
              child: TextField(
                controller: textController,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: onChanged,
                style: _scaledTextStyle(
                  Theme.of(context).textTheme.bodyMedium,
                  displaySettings.messageFontScale,
                ),
                decoration: const InputDecoration(
                  hintText: '输入消息与 AI 聊天',
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                enabled: !controller.isSending,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _ComposerToolIcon(
                  tooltip: '快捷命令',
                  icon: Icons.auto_awesome,
                  color: colors.secondary,
                  onPressed: onShortcutCommandsPressed,
                ),
                const SizedBox(width: 18),
                _ComposerToolIcon(
                  tooltip: '快捷短语',
                  icon: Icons.bolt_outlined,
                  onPressed: onQuickPhrasesPressed,
                ),
                const Spacer(),
                const _ComposerToolIcon(icon: Icons.add),
                const SizedBox(width: 10),
                _ComposerSendButton(
                  isSending: controller.isSending,
                  onPressed: onSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerSendButton extends StatelessWidget {
  const _ComposerSendButton({
    required this.isSending,
    required this.onPressed,
  });

  final bool isSending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabledColor = colors.surfaceContainerHigh;
    final foreground = isSending ? colors.onSurfaceVariant : colors.onPrimary;

    return Tooltip(
      message: '发送',
      child: SizedBox.square(
        dimension: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSending ? disabledColor : null,
            gradient: isSending
                ? null
                : LinearGradient(
                    colors: <Color>[
                      colors.primary,
                      Color.alphaBlend(
                        colors.secondary.withValues(alpha: 0.34),
                        colors.primary,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            shape: BoxShape.circle,
            boxShadow: isSending
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isSending ? null : onPressed,
              child: Center(
                child: isSending
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Icon(Icons.arrow_upward, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerToolIcon extends StatelessWidget {
  const _ComposerToolIcon({
    required this.icon,
    this.color,
    this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color? color;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.onSurfaceVariant;
    final iconWidget = DecoratedBox(
      decoration: BoxDecoration(
        color: color == null
            ? colors.surfaceContainerHigh.withValues(alpha: 0.72)
            : colors.primaryContainer.withValues(alpha: 0.44),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: foreground,
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return iconWidget;
    }

    return Tooltip(
      message: tooltip ?? '',
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: iconWidget,
      ),
    );
  }
}

class _ShortcutCommandListSheet extends StatelessWidget {
  const _ShortcutCommandListSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '快捷命令',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const _ShortcutCommandEmptyState(),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCommandEmptyState extends StatelessWidget {
  const _ShortcutCommandEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.auto_awesome,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '暂无快捷命令',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPhrasePickerSheet extends StatelessWidget {
  const _QuickPhrasePickerSheet({
    required this.phrases,
  });

  final List<ChatQuickPhrase> phrases;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '快捷短语',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: phrases.length,
                itemBuilder: (context, index) {
                  final phrase = phrases[index];
                  return ListTile(
                    key: Key('quick_phrase_picker_${phrase.id}'),
                    title: Text(phrase.title),
                    subtitle: Text(
                      phrase.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.flash_on_outlined),
                    onTap: () => Navigator.of(context).pop(phrase),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
