import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/step_header_card.dart';
import 'package:how_many_mobile_meeple/components/info_message_box.dart';
import 'package:how_many_mobile_meeple/api/prefetch_service.dart';

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
    return Consumer<AppModel>(
      builder: (context, model, child) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                _buildInputContent(
                    context, model, ItemType.collection, 'Collection')
              else
                _buildInputContent(
                    context, model, ItemType.geekList, 'Geeklist'),
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
          const EdgeInsets.symmetric(horizontal: 2),
        ),
      ),
      segments: [
        const ButtonSegment(
          value: 0,
          label: Text('Trending', overflow: TextOverflow.ellipsis, maxLines: 1),
          icon: Icon(Icons.local_fire_department, size: 16),
        ),
        const ButtonSegment(
          value: 1,
          label:
              Text('Collection', overflow: TextOverflow.ellipsis, maxLines: 1),
          icon: Icon(Icons.person, size: 16),
        ),
        const ButtonSegment(
          value: 2,
          label: Text('Geeklist', overflow: TextOverflow.ellipsis, maxLines: 1),
          icon: Icon(Icons.list, size: 16),
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
                  label: const Text('Trending Games Added'),
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
                  label: const Text('Use Trending Games'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInputContent(
      BuildContext context, AppModel model, ItemType itemType, String label) {
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

    final isPrimary = item.itemType == ItemType.collection &&
        model.primaryPlayer == item.name;

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
            if (item.itemType == ItemType.collection)
              IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.crown,
                  size: 16,
                  color: isPrimary ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  model.primaryPlayer = item.name;
                },
                tooltip: isPrimary ? 'Primary player' : 'Set as primary player',
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
