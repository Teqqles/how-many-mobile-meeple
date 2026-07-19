import 'package:flutter/material.dart';

import 'help_content.dart';

/// Full help page listing every section. When opened with [initialSectionId]
/// it scrolls to and briefly highlights that page's section, so help always
/// opens in the context of where the user came from.
class HelpPage extends StatefulWidget {
  final String? initialSectionId;

  const HelpPage({super.key, this.initialSectionId});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final Map<String, GlobalKey> _sectionKeys = {
    for (final section in HelpContent.sections) section.id: GlobalKey(),
  };

  String? _highlightedId;

  @override
  void initState() {
    super.initState();
    final target = widget.initialSectionId;
    if (target != null && _sectionKeys.containsKey(target)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(target));
    }
  }

  Future<void> _scrollTo(String id) async {
    final key = _sectionKeys[id];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      alignment: 0.05,
      curve: Curves.easeInOut,
    );

    if (!mounted) return;
    setState(() => _highlightedId = id);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _highlightedId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(context),
          const SizedBox(height: 16),
          for (final section in HelpContent.sections) ...[
            _buildSection(context, section),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Text(
      'Here is what each part of How Many Meeple? does and where to find it. '
      'Open Help from any page to jump straight to that page\'s guidance.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildSection(BuildContext context, HelpSection section) {
    final isHighlighted = _highlightedId == section.id;
    final theme = Theme.of(context);

    return AnimatedContainer(
      key: _sectionKeys[section.id],
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(section.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(section.summary),
              const SizedBox(height: 12),
              ...section.items.map((item) => _buildItem(context, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, HelpItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
