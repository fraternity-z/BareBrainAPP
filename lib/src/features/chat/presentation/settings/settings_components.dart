import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color settingsPageBackground = Color(0xfffbfafd);
const Color settingsCardBackground = Colors.white;
const Color settingsPrimaryText = Color(0xff303036);
const Color settingsSecondaryText = Color(0xff85858d);
const Color settingsDividerColor = Color(0xfff0f0f3);

class SettingsScreenFrame extends StatelessWidget {
  const SettingsScreenFrame({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: settingsPageBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SettingsTopBar(title: title, actions: actions),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class SettingsTopBar extends StatelessWidget {
  const SettingsTopBar({
    required this.title,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 10, 26, 8),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: '返回',
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.transparent,
                fixedSize: const Size.square(42),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.arrow_back, size: 30),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.topPadding = 18,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xff56565f),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: settingsCardBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: _withDividers(children),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> source) {
    final widgets = <Widget>[];
    for (var index = 0; index < source.length; index++) {
      widgets.add(source[index]);
      if (index < source.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: settingsDividerColor,
            indent: 74,
            endIndent: 20,
          ),
        );
      }
    }
    return widgets;
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.iconColor = settingsPrimaryText,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 18, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final valueMaxWidth = math.min(
                  constraints.maxWidth * 0.38,
                  280.0,
                );

                return Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 34,
                      child: Icon(icon, size: 30, color: iconColor),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: settingsPrimaryText,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    if (value != null) ...<Widget>[
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: valueMaxWidth),
                        child: Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: settingsSecondaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right,
                      size: 30,
                      color: settingsPrimaryText,
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

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 18, 8),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: 34,
                  child: Icon(icon, size: 30, color: settingsPrimaryText),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: settingsPrimaryText,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: settingsSecondaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsFormPanel extends StatelessWidget {
  const SettingsFormPanel({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: settingsDividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class SettingsFeedbackBanner extends StatelessWidget {
  const SettingsFeedbackBanner({
    required this.message,
    this.succeeded = false,
    super.key,
  });

  final String message;
  final bool succeeded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background =
        succeeded ? colors.secondaryContainer : colors.errorContainer;
    final foreground =
        succeeded ? colors.onSecondaryContainer : colors.onErrorContainer;
    final border = succeeded ? colors.secondary : colors.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(
              succeeded ? Icons.check_circle_outline : Icons.error_outline,
              color: foreground,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
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

class SettingsEmptyState extends StatelessWidget {
  const SettingsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settingsCardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 38, color: settingsSecondaryText),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: settingsPrimaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: settingsSecondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
