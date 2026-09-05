import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 2.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: tanoTeal.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11.0,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1.0,
            thickness: 0.5,
            indent: 16.0,
            endIndent: 0.0,
            color: primaryTextColor(context).withValues(alpha: 0.08),
          ),
        );
      }
    }

    return Card(
      elevation: 0.0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(children: dividedChildren),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.textColor,
    this.fontWeight,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -4.0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      dense: true,
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (selected ? tanoTeal : primaryTextColor(context)),
          fontWeight: fontWeight ?? (selected ? FontWeight.bold : FontWeight.normal),
          fontSize: 14.0,
        ),
      ),
      trailing: trailing ??
          (selected ? const Icon(Icons.check_circle, color: tanoTeal, size: 16.0) : null),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -4.0),
      contentPadding: const EdgeInsets.only(left: 16.0, right: 10.0),
      dense: true,
      title: Text(
        title,
        style: TextStyle(color: primaryTextColor(context), fontSize: 14.0),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: tanoTeal,
        ),
      ),
    );
  }
}
