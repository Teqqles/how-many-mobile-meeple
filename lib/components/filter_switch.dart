import 'package:flutter/material.dart';

/// Common Switch widget for homepage/advanced mode filter components
/// Provides consistent styling for all filter switches
class FilterSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const FilterSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      activeThumbColor: Colors.white,
      activeTrackColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      inactiveThumbColor: Colors.grey[600],
      inactiveTrackColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      onChanged: onChanged,
      value: value,
    );
  }
}
