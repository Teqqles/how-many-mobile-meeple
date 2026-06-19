import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/step_header_card.dart';
import 'package:how_many_mobile_meeple/components/info_message_box.dart';
import 'package:how_many_mobile_meeple/api/prefetch_service.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_service.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_storage.dart';

/// Step 1: Select Source of Games
/// Tabbed UI: Trending (hot list) vs My Collection (BGG username/geeklist)
class Step1SelectSource extends StatefulWidget {
  const Step1SelectSource({super.key});

  @override
  State<Step1SelectSource> createState() => _Step1SelectSourceState();
}

class _Step1SelectSourceState extends State<Step1SelectSource> {
  static const _tabKey = 'step1_selected_tab';

  final TextEditingController _controller = TextEditingController();
  int _tabIndex = 0;
  bool _tourTriggered = false;

  final GlobalKey _tabSelectorKey = GlobalKey(debugLabel: 'step1_tab_selector');
  final GlobalKey _trendingContentKey = GlobalKey(debugLabel: 'step1_trending');
  final GlobalKey _collectionInputKey =
      GlobalKey(debugLabel: 'step1_collection');
  final GlobalKey _geeklistInputKey = GlobalKey(debugLabel: 'step1_geeklist');

  @override
  void initState() {
    super.initState();
    _loadSavedTab();
  }

  Future<void> _loadSavedTab() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_tabKey);
    if (saved != null && mounted) {
      setState(() => _tabIndex = saved);
    }
  }

  Future<void> _saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, index);
  }

  void _triggerStep1Tour() {
    if (_tourTriggered) return;
    _tourTriggered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final service = await TourTipService.instance();
      if (!service.isEnabled) return;

      final storage = await TourTipStorage.create();
      final tipIds = [
        'step1_tab_selector',
        'step1_trending',
        'step1_collection',
        'step1_geeklist',
      ];
      final unseen = tipIds.where((id) => !storage.isSeen(id)).toList();
      if (unseen.isEmpty) return;

      if (_tabSelectorKey.currentContext == null) return;

      while (service.isShowing) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (!service.isEnabled) return;

      final steps = <_Step1TipStep>[
        if (unseen.contains('step1_tab_selector'))
          _Step1TipStep(
            key: _tabSelectorKey,
            id: 'step1_tab_selector',
            title: 'Choose Your Source',
            description:
                'Switch between Trending games, your BGG Collection, or a Geeklist. You can add multiple sources.',
          ),
        if (unseen.contains('step1_trending'))
          _Step1TipStep(
            key: _trendingContentKey,
            id: 'step1_trending',
            title: 'Trending Games',
            description:
                'Browse the hottest games on BoardGameGeek right now - no account needed. Just tap to add them as a source.',
            tabIndex: 0,
          ),
        if (unseen.contains('step1_collection'))
          _Step1TipStep(
            key: _collectionInputKey,
            id: 'step1_collection',
            title: 'My Collection',
            description:
                'Enter your BoardGameGeek username to search within your own game collection.',
            tabIndex: 1,
          ),
        if (unseen.contains('step1_geeklist'))
          _Step1TipStep(
            key: _geeklistInputKey,
            id: 'step1_geeklist',
            title: 'Geeklist',
            description:
                'Enter a BGG Geeklist ID to search games from a community-curated list.',
            tabIndex: 2,
          ),
      ];

      if (steps.isEmpty) return;

      _dismissed = false;
      for (final step in steps) {
        if (!mounted || _dismissed || !service.isEnabled) break;

        if (step.tabIndex != null) {
          _switchToTab(step.tabIndex!);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted || _dismissed) break;
        }

        if (step.key.currentContext == null) continue;

        await _showSingleTip(step, service, storage, tipIds);
      }

      if (mounted) _switchToTab(0);

      for (final id in tipIds) {
        await storage.markSeen(id);
      }
    });
  }

  static const double _maxFocusRadius = 150.0;

  double _cappedPaddingForKey(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 10;
    final screenWidth = MediaQuery.of(key.currentContext!).size.width;
    final targetSize = renderBox.size;
    final maxDimension = math.max(targetSize.width, targetSize.height);
    final maxRadius = math.min(_maxFocusRadius, screenWidth * 0.2);
    final padding = maxRadius - maxDimension * 0.6;
    return math.max(padding, 4);
  }

  bool _dismissed = false;

  Future<void> _showSingleTip(
    _Step1TipStep step,
    TourTipService service,
    TourTipStorage storage,
    List<String> tipIds,
  ) async {
    final completer = Completer<void>();

    final padding = _cappedPaddingForKey(step.key);

    final target = TargetFocus(
      identify: step.id,
      keyTarget: step.key,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      enableTargetTab: true,
      paddingFocus: padding,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          _dismissed = true;
                          await service.dismissAll();
                          for (final tid in tipIds) {
                            await storage.markSeen(tid);
                          }
                          _activeCoachMark?.skip();
                        },
                        child: const Text(
                          'Dismiss Tour',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );

    _activeCoachMark = TutorialCoachMark(
      targets: [target],
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      hideSkip: true,
      onFinish: () => completer.complete(),
      onSkip: () {
        _dismissed = true;
        completer.complete();
        return true;
      },
    )..show(context: context);

    await completer.future;
    _activeCoachMark = null;
  }

  TutorialCoachMark? _activeCoachMark;

  void _switchToTab(int index) {
    if (mounted) {
      setState(() {
        _tabIndex = index;
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _hasHotList(AppModel model) {
    return model.items.itemList
        .any((item) => item.itemType == ItemType.hotList);
  }

  @override
  Widget build(BuildContext context) {
    _triggerStep1Tour();
    return Consumer<AppModel>(
      builder: (context, model, child) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepHeaderCard(
                icon: Icons.source,
                title: 'Select Source of Games',
                subtitle: 'Choose where to find games',
              ),
              const SizedBox(height: 20),
              _buildTabSelector(context),
              const SizedBox(height: 20),
              if (_tabIndex == 0)
                _buildTrendingContent(context, model)
              else if (_tabIndex == 1)
                _buildInputContent(context, model, ItemType.collection,
                    'Collection', _collectionInputKey)
              else
                _buildInputContent(context, model, ItemType.geekList,
                    'Geeklist', _geeklistInputKey),
              // Show added sources (shared across both tabs)
              if (model.items.itemList.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Added Sources (${model.items.itemList.length}/${AppCommon.maxItemsFromBgg})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...model.items.itemList
                    .map((item) => _buildSourceChip(context, model, item)),
              ],
              // Status message
              if (model.items.itemList.isEmpty) ...[
                const SizedBox(height: 24),
                const InfoMessageBox.warning(
                  message: 'Please add at least one source to find games',
                ),
              ] else ...[
                const SizedBox(height: 24),
                const InfoMessageBox.success(
                  message:
                      'Great! You can add more sources or continue to the next step',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      segments: [
        ButtonSegment(
          value: 0,
          label: Text('Trending', key: _tabSelectorKey),
          icon: const Icon(Icons.local_fire_department, size: 18),
        ),
        const ButtonSegment(
          value: 1,
          label: Text('My Collection'),
          icon: Icon(Icons.person, size: 18),
        ),
        const ButtonSegment(
          value: 2,
          label: Text('Geeklist'),
          icon: Icon(Icons.list, size: 18),
        ),
      ],
      selected: {_tabIndex},
      onSelectionChanged: (Set<int> selection) {
        setState(() {
          _tabIndex = selection.first;
          _controller.clear();
        });
        _saveTab(selection.first);
      },
    );
  }

  Widget _buildTrendingContent(BuildContext context, AppModel model) {
    final hasHot = _hasHotList(model);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse the hottest games on BoardGameGeek - no account needed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: hasHot
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    'Trending Games Added',
                    key: _trendingContentKey,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                )
              : FilledButton.tonalIcon(
                  onPressed:
                      model.items.itemList.length >= AppCommon.maxItemsFromBgg
                          ? null
                          : () => _addHotList(model),
                  icon: const Icon(Icons.local_fire_department),
                  label: Text(
                    'Use Trending Games',
                    key: _trendingContentKey,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInputContent(BuildContext context, AppModel model,
      ItemType itemType, String label, GlobalKey fieldKey) {
    final isCollection = itemType == ItemType.collection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          enabled: model.items.itemList.length < AppCommon.maxItemsFromBgg,
          decoration: InputDecoration(
            labelText: isCollection ? 'BoardGameGeek Username' : 'Geeklist ID',
            hintText: isCollection ? 'e.g., testuser1' : 'e.g., 12345',
            prefixIcon: Icon(
              key: fieldKey,
              isCollection ? Icons.person_outline : Icons.format_list_numbered,
            ),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            helperText: model.items.itemList.length >= AppCommon.maxItemsFromBgg
                ? 'Maximum ${AppCommon.maxItemsFromBgg} sources reached'
                : null,
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: (_) => _addSource(model, itemType),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _controller.text.isEmpty ||
                    model.items.itemList.length >= AppCommon.maxItemsFromBgg
                ? null
                : () => _addSource(model, itemType),
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Add $label'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  void _addHotList(AppModel model) {
    final item = Item('trending', itemType: ItemType.hotList);
    model.addItem(item);
    PrefetchService.warmCache(item);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added trending games as a source'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addSource(AppModel model, ItemType itemType) {
    if (_controller.text.isEmpty) return;

    final item = Item(_controller.text.trim());
    item.itemType = itemType;
    model.addItem(item);
    PrefetchService.warmCache(item);

    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${itemType == ItemType.collection ? 'collection' : 'geeklist'}: ${item.name}',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSourceChip(BuildContext context, AppModel model, Item item) {
    final IconData icon;
    final String label;
    if (item.itemType == ItemType.hotList) {
      icon = Icons.local_fire_department;
      label = 'Trending Games';
    } else if (item.itemType == ItemType.collection) {
      icon = Icons.person;
      label = item.name;
    } else {
      icon = Icons.format_list_bulleted;
      label = item.name;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                model.deleteItem(item);
              },
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1TipStep {
  final GlobalKey key;
  final String id;
  final String title;
  final String description;
  final int? tabIndex;

  const _Step1TipStep({
    required this.key,
    required this.id,
    required this.title,
    required this.description,
    this.tabIndex,
  });
}
