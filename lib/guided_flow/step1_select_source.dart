import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/step_header_card.dart';
import 'package:how_many_mobile_meeple/components/info_message_box.dart';
import 'package:how_many_mobile_meeple/api/prefetch_service.dart';

/// Step 1: Select Source of Games
/// Allows users to add BGG usernames or geeklist IDs
class Step1SelectSource extends StatefulWidget {
  const Step1SelectSource({super.key});

  @override
  State<Step1SelectSource> createState() => _Step1SelectSourceState();
}

class _Step1SelectSourceState extends State<Step1SelectSource> {
  final TextEditingController _controller = TextEditingController();
  ItemType _selectedType = ItemType.collection;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              const StepHeaderCard(
                icon: Icons.source,
                title: 'Select Source of Games',
                subtitle: 'Add your BGG username or a geeklist',
              ),

              const SizedBox(height: 24),

              // Source type selector
              SegmentedButton<ItemType>(
                segments: const [
                  ButtonSegment(
                    value: ItemType.collection,
                    label: Text('Username'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: ItemType.geekList,
                    label: Text('Geeklist'),
                    icon: Icon(Icons.list),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<ItemType> selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Input field
              TextField(
                controller: _controller,
                enabled:
                    model.items.itemList.length < AppCommon.maxItemsFromBgg,
                decoration: InputDecoration(
                  labelText: _selectedType == ItemType.collection
                      ? 'BoardGameGeek Username'
                      : 'Geeklist ID',
                  hintText: _selectedType == ItemType.collection
                      ? 'e.g., testuser1'
                      : 'e.g., 12345',
                  prefixIcon: Icon(
                    _selectedType == ItemType.collection
                        ? Icons.person_outline
                        : Icons.format_list_numbered,
                  ),
                  border: const OutlineInputBorder(),
                  helperText: model.items.itemList.length >=
                          AppCommon.maxItemsFromBgg
                      ? 'Maximum ${AppCommon.maxItemsFromBgg} sources reached'
                      : null,
                ),
                onChanged: (value) => setState(() {}),
                onSubmitted: (_) => _addSource(model),
              ),

              const SizedBox(height: 16),

              // Add button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _controller.text.isEmpty ||
                          model.items.itemList.length >=
                              AppCommon.maxItemsFromBgg
                      ? null
                      : () => _addSource(model),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Source'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              // Show added sources
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

              // Required step message
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

  void _addSource(AppModel model) {
    if (_controller.text.isEmpty) return;

    final item = Item(_controller.text.trim());
    item.itemType = _selectedType;
    model.addItem(item);
    PrefetchService.warmCache(item);

    _controller.clear();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${_selectedType == ItemType.collection ? 'username' : 'geeklist'}: ${item.name}',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSourceChip(BuildContext context, AppModel model, Item item) {
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
              item.itemType == ItemType.collection
                  ? Icons.person
                  : Icons.format_list_bulleted,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
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
