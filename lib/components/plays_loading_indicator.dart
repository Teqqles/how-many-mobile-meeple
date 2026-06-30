import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';

class PlaysLoadingIndicator extends StatefulWidget {
  const PlaysLoadingIndicator({super.key});

  @override
  State<PlaysLoadingIndicator> createState() => _PlaysLoadingIndicatorState();
}

class _PlaysLoadingIndicatorState extends State<PlaysLoadingIndicator> {
  @override
  void initState() {
    super.initState();
    final model = Provider.of<AppModel>(context, listen: false);
    if (!model.playsLoaded && model.primaryPlayer != null) {
      model.loadPlays();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppModel, bool>(
      selector: (_, model) =>
          !model.playsLoaded && model.primaryPlayer != null,
      builder: (context, showLoading, child) {
        if (!showLoading) return const SizedBox.shrink();
        return const LinearProgressIndicator();
      },
    );
  }
}
