import 'package:flutter/material.dart';

class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      avatar: avatar,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      avatar: avatar,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class AppMechanicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool>? onSelected;

  const AppMechanicChip({
    super.key,
    required this.label,
    required this.selected,
    this.enabled = true,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? onSelected : null,
      selectedColor: Theme.of(context).colorScheme.secondary,
      disabledColor: Colors.grey[100],
      backgroundColor: enabled ? Colors.grey[200] : Colors.grey[100],
      elevation: enabled ? 2 : 0,
      side: BorderSide(
        color: enabled
            ? (selected
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey[400]!)
            : Colors.grey[300]!,
        width: 1.5,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: selected && enabled
            ? Colors.white
            : (enabled ? Colors.black87 : Theme.of(context).disabledColor),
      ),
    );
  }
}
