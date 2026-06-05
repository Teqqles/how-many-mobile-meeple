import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/theme_extensions.dart';

/// Reusable badge widget for displaying filter values
/// Shows a value in a rounded rectangle with colored background
class FilterValueBadge extends StatelessWidget {
  final String value;
  final bool isEnabled;

  const FilterValueBadge({
    super.key,
    required this.value,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: isEnabled
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).disabledColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: AppDefaultPadding(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).selectedRowColor,
          ),
        ),
      ),
    );
  }
}
