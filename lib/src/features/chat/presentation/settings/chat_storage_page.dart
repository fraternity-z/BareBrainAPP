import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/chat_controller.dart';
import 'settings_components.dart';

typedef LoadChatStorageUsage = Future<ChatStorageUsage> Function();

class ChatStoragePage extends StatefulWidget {
  const ChatStoragePage({
    this.loadStorageUsage,
    super.key,
  });

  final LoadChatStorageUsage? loadStorageUsage;

  @override
  State<ChatStoragePage> createState() => _ChatStoragePageState();
}

class _ChatStoragePageState extends State<ChatStoragePage> {
  ChatStorageUsage? _usage;
  String? _errorMessage;
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshUsage());
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage ?? const ChatStorageUsage.empty();
    final cacheItemCount = usage.catalogBytes > 0 ? 1 : 0;
    return SettingsScreenFrame(
      title: '存储空间',
      actions: <Widget>[
        IconButton(
          tooltip: '刷新',
          onPressed: _isLoading ? null : () => unawaited(_refreshUsage()),
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.refresh, size: 30),
        ),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: <Widget>[
          _StorageOverviewCard(
            usage: usage,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onRetry: () => unawaited(_refreshUsage()),
          ),
          const SizedBox(height: 18),
          _StorageListCard(
            rows: <Widget>[
              _StorageCategoryRow(
                icon: Icons.chat_bubble_outline,
                title: '聊天记录',
                value:
                    '${_formatBytes(usage.snapshotBytes)} · ${usage.conversationCount} 个会话',
              ),
              const _StorageCategoryRow(
                icon: Icons.smart_toy_outlined,
                title: '助手',
                value: '0 B · 0 项',
              ),
              _StorageCategoryRow(
                icon: Icons.widgets_outlined,
                title: '缓存',
                value:
                    '${_formatBytes(usage.catalogBytes)} · $cacheItemCount 项',
              ),
              const _StorageCategoryRow(
                icon: Icons.description_outlined,
                title: '日志',
                value: '0 B · 0 条',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshUsage() async {
    final loadStorageUsage = widget.loadStorageUsage;
    if (loadStorageUsage == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _usage = const ChatStorageUsage.empty();
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usage = await loadStorageUsage();
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _usage = usage;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _errorMessage = '读取存储空间失败：$error';
        _isLoading = false;
      });
    }
  }
}

class _StorageOverviewCard extends StatelessWidget {
  const _StorageOverviewCard({
    required this.usage,
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final ChatStorageUsage usage;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final totalBytes = usage.totalBytes;
    final textTheme = Theme.of(context).textTheme;
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '已用空间',
                    style: textTheme.titleMedium?.copyWith(
                      color: strong,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _formatBytes(totalBytes),
              style: textTheme.displayMedium?.copyWith(
                color: strong,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 24),
            _StorageUsageBar(
              chatBytes: usage.snapshotBytes,
              cacheBytes: usage.catalogBytes,
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 24,
              runSpacing: 10,
              children: <Widget>[
                _StorageLegendItem(
                  color: Color(0xff22c864),
                  label: '聊天记录',
                ),
                _StorageLegendItem(
                  color: Color(0xffff4248),
                  label: '缓存',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '共发现可清理空间 ${_formatBytes(usage.catalogBytes)}',
              style: textTheme.bodyLarge?.copyWith(
                color: soft,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (errorMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              SettingsFeedbackBanner(message: errorMessage!),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重新读取'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StorageUsageBar extends StatelessWidget {
  const _StorageUsageBar({
    required this.chatBytes,
    required this.cacheBytes,
  });

  final int chatBytes;
  final int cacheBytes;

  @override
  Widget build(BuildContext context) {
    final totalBytes = chatBytes + cacheBytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: double.infinity,
        height: 16,
        child: totalBytes <= 0
            ? ColoredBox(color: settingsDividerColorFor(context))
            : Row(
                children: <Widget>[
                  if (chatBytes > 0)
                    Expanded(
                      flex: _segmentFlex(chatBytes, totalBytes),
                      child: const ColoredBox(color: Color(0xff22c864)),
                    ),
                  if (cacheBytes > 0)
                    Expanded(
                      flex: _segmentFlex(cacheBytes, totalBytes),
                      child: const ColoredBox(color: Color(0xffff4248)),
                    ),
                ],
              ),
      ),
    );
  }

  int _segmentFlex(int bytes, int totalBytes) {
    if (totalBytes <= 0) {
      return 1;
    }

    return (bytes / totalBytes * 1000).round().clamp(1, 1000).toInt();
  }
}

class _StorageLegendItem extends StatelessWidget {
  const _StorageLegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: const SizedBox.square(dimension: 13),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: settingsSecondaryTextColor(context),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _StorageListCard extends StatelessWidget {
  const _StorageListCard({
    required this.rows,
  });

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(settingsCardRadius),
        child: Column(children: _withDividers(context)),
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context) {
    final widgets = <Widget>[];
    for (var index = 0; index < rows.length; index++) {
      widgets.add(rows[index]);
      if (index < rows.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            thickness: 1,
            color: settingsDividerColorFor(context),
            indent: 74,
            endIndent: 18,
          ),
        );
      }
    }
    return widgets;
  }
}

class _StorageCategoryRow extends StatelessWidget {
  const _StorageCategoryRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final strong = settingsPrimaryTextColor(context);
    final soft = settingsSecondaryTextColor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 94),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 32, color: strong),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: strong,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: soft,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: strong, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = <String>['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  if (unitIndex == 0) {
    return '${value.toStringAsFixed(0)} ${units[unitIndex]}';
  }

  final fractionDigits = value < 10 ? 2 : 1;
  return '${value.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
}
