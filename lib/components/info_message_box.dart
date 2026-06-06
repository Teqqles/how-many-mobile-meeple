import 'package:flutter/material.dart';

/// Reusable info message box widget
/// Displays an icon with a message in a rounded, colored container
class InfoMessageBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final InfoMessageType type;

  const InfoMessageBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.type = InfoMessageType.info,
  });

  const InfoMessageBox.info({
    super.key,
    required this.message,
  })  : icon = Icons.info_outline,
        type = InfoMessageType.info;

  const InfoMessageBox.success({
    super.key,
    required this.message,
  })  : icon = Icons.check_circle_outline,
        type = InfoMessageType.success;

  const InfoMessageBox.warning({
    super.key,
    required this.message,
  })  : icon = Icons.warning_amber_outlined,
        type = InfoMessageType.warning;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context);
    final iconColor = _getIconColor(context);
    final textColor = _getTextColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case InfoMessageType.info:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      case InfoMessageType.success:
        return Theme.of(context).colorScheme.primaryContainer;
      case InfoMessageType.warning:
        return Theme.of(context).colorScheme.errorContainer;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (type) {
      case InfoMessageType.info:
        return Theme.of(context).colorScheme.primary;
      case InfoMessageType.success:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case InfoMessageType.warning:
        return Theme.of(context).colorScheme.error;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (type) {
      case InfoMessageType.info:
        return Theme.of(context).colorScheme.onSurface;
      case InfoMessageType.success:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case InfoMessageType.warning:
        return Theme.of(context).colorScheme.onErrorContainer;
    }
  }
}

enum InfoMessageType {
  info,
  success,
  warning,
}
