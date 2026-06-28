import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/unplayed_only_toggle.dart';

class ShelfOfShameFilterWidget extends StatelessWidget {
  const ShelfOfShameFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnplayedOnlyToggle(style: UnplayedToggleStyle.compact);
  }
}
