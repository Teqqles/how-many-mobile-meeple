import 'package:flutter/material.dart';

/// Common Switch widget for drawer components
/// Provides consistent styling for all drawer switches
class DrawerSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const DrawerSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      activeThumbColor: Colors.white,
      activeTrackColor: Theme.of(context).colorScheme.primary,
      inactiveThumbColor: Colors.grey[600],
      inactiveTrackColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      onChanged: onChanged,
      value: value,
    );
  }
}
