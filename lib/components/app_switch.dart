import 'package:flutter/material.dart';

enum AppSwitchStyle { prominent, subtle }

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final AppSwitchStyle style;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = AppSwitchStyle.prominent,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Switch(
      activeThumbColor: Colors.white,
      activeTrackColor: style == AppSwitchStyle.prominent
          ? primary
          : primary.withValues(alpha: 0.5),
      inactiveThumbColor: Colors.grey[600],
      inactiveTrackColor: primary.withValues(alpha: 0.5),
      onChanged: onChanged,
      value: value,
    );
  }
}
