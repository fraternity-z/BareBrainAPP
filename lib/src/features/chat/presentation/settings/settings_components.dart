import 'dart:math' as math;

import 'package:flutter/material.dart';

const double settingsCardRadius = 20;
const Color settingsPageBackground = Color(0xfffbf9fd);
const Color settingsCardBackground = Colors.white;
const Color settingsPrimaryText = Color(0xff171717);
const Color settingsSecondaryText = Color(0xff6f6f75);
const Color settingsDividerColor = Color(0xffefeff2);

Color settingsPageBackgroundColor(BuildContext context) {
  return _SettingsPalette.of(context).background;
}

Color settingsCardBackgroundColor(BuildContext context) {
  return _SettingsPalette.of(context).card;
}

Color settingsPrimaryTextColor(BuildContext context) {
  return _SettingsPalette.of(context).textStrong;
}

Color settingsSecondaryTextColor(BuildContext context) {
  return _SettingsPalette.of(context).textSoft;
}

Color settingsDividerColorFor(BuildContext context) {
  return _SettingsPalette.of(context).divider;
}

BoxDecoration settingsCardDecoration(BuildContext context) {
  final palette = _SettingsPalette.of(context);
  return BoxDecoration(
    color: palette.card,
    borderRadius: BorderRadius.circular(settingsCardRadius),
    border: Border.all(color: palette.divider.withValues(alpha: 0.35)),
    boxShadow: palette.cardShadow,
  );
}

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
    final palette = _SettingsPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
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
    final palette = _SettingsPalette.of(context);
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: palette.textStrong,
      backgroundColor: Colors.transparent,
      fixedSize: const Size.square(48),
      shape: const CircleBorder(),
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: palette.background),
      child: SizedBox(
        height: 100,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: '返回',
                onPressed: () => Navigator.of(context).maybePop(),
                style: buttonStyle,
                icon: const Icon(Icons.arrow_back, size: 31),
              ),
              const SizedBox(width: 26),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: palette.textStrong,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
              ),
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(width: 12),
                IconButtonTheme(
                  data: IconButtonThemeData(style: buttonStyle),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
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
    final palette = _SettingsPalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.textSoft,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: settingsCardDecoration(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(settingsCardRadius),
              child: Column(
                children: _withDividers(context, children),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context, List<Widget> source) {
    final palette = _SettingsPalette.of(context);
    final widgets = <Widget>[];
    for (var index = 0; index < source.length; index++) {
      widgets.add(source[index]);
      if (index < source.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            thickness: 1,
            color: palette.divider,
            indent: 74,
            endIndent: 18,
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
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final valueMaxWidth = math.min(
                  constraints.maxWidth * 0.36,
                  220.0,
                );

                return Row(
                  children: <Widget>[
                    _SettingsIconBox(
                      icon: icon,
                      iconColor: iconColor ?? palette.textStrong,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: palette.textStrong,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
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
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: palette.textSoft,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: palette.textSoft,
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
    final palette = _SettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            child: Row(
              children: <Widget>[
                _SettingsIconBox(icon: icon),
                const SizedBox(width: 14),
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
                                  color: palette.textStrong,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
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
                                    color: palette.textSoft,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
      decoration: settingsCardDecoration(context),
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
        borderRadius: BorderRadius.circular(settingsCardRadius),
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
                      letterSpacing: 0,
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
    final palette = _SettingsPalette.of(context);
    return DecoratedBox(
      decoration: settingsCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        child: Column(
          children: <Widget>[
            _SettingsIconBox(icon: icon, dimension: 46, iconSize: 26),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.textStrong,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSoft,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIconBox extends StatelessWidget {
  const _SettingsIconBox({
    required this.icon,
    this.iconColor,
    this.dimension = 42,
    this.iconSize = 23,
  });

  final IconData icon;
  final Color? iconColor;
  final double dimension;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.iconBackground,
        borderRadius: BorderRadius.circular(settingsCardRadius),
        border: Border.all(color: palette.divider),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? palette.textStrong,
        ),
      ),
    );
  }
}

class _SettingsPalette {
  const _SettingsPalette({
    required this.background,
    required this.card,
    required this.iconBackground,
    required this.textStrong,
    required this.textSoft,
    required this.divider,
    required this.cardShadow,
  });

  final Color background;
  final Color card;
  final Color iconBackground;
  final Color textStrong;
  final Color textSoft;
  final Color divider;
  final List<BoxShadow> cardShadow;

  static _SettingsPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SettingsPalette(
        background: Color(0xff101011),
        card: Color(0xff1b1b1d),
        iconBackground: Color(0xff242426),
        textStrong: Color(0xfff4f4f5),
        textSoft: Color(0xffa6a6aa),
        divider: Color(0xff303034),
        cardShadow: <BoxShadow>[],
      );
    }

    return const _SettingsPalette(
      background: settingsPageBackground,
      card: settingsCardBackground,
      iconBackground: Color(0xfff2f2f3),
      textStrong: settingsPrimaryText,
      textSoft: settingsSecondaryText,
      divider: settingsDividerColor,
      cardShadow: <BoxShadow>[],
    );
  }
}
