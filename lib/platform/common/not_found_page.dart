import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

/// Shown when a route cannot be matched - a broken or mistyped link - so the
/// visitor lands on a clear "not found" screen with a way home rather than a
/// blank page or a silent redirect.
class NotFoundPage extends StatelessWidget {
  final Uri location;

  const NotFoundPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off, size: 72, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Oops - we couldn\'t find that page',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The link "${location.path}" doesn\'t match anything here. '
                'It may be broken or out of date.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('not-found-home'),
                onPressed: () => context.go(r.Router.homeRoute),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
