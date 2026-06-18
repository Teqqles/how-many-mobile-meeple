import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoadingFunFacts extends StatefulWidget {
  const LoadingFunFacts({super.key});

  static Future<List<String>> _loadFacts() async {
    final text = await rootBundle.loadString('lib/assets/fun_facts.txt');
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  State<LoadingFunFacts> createState() => _LoadingFunFactsState();
}

class _LoadingFunFactsState extends State<LoadingFunFacts> {
  List<String> _facts = [];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    LoadingFunFacts._loadFacts().then((facts) {
      if (!mounted) return;
      setState(() {
        _facts = facts;
        _currentIndex = Random().nextInt(facts.length);
      });
      _timer = Timer.periodic(const Duration(seconds: 20), (_) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _facts.length;
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_facts.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        key: ValueKey<int>(_currentIndex),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          _facts[_currentIndex],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
