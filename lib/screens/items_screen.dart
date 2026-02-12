import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/scrollable_data_table.dart';
import '../widgets/section_card.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _searchController = TextEditingController();
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _service = SupabaseService(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.fetchItems(userId),
    ]);
    setState(() {
      _items = results[0];
      _loading = false;
    });
  }

  Future<void> _openItemDialog({Map<String, dynamic>? item}) async {
    final titleController = TextEditingController(text: item?['title'] ?? '');
    final descriptionController = TextEditingController(text: item?['description'] ?? '');
    final brandController = TextEditingController(text: item?['brand'] ?? '');
    final categoryController = TextEditingController(text: item?['category'] ?? '');
    final sizeController = TextEditingController(text: item?['size'] ?? '');
    final colourController = TextEditingController(text: item?['colour'] ?? '');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'Size')),
              TextField(controller: colourController, decoration: const InputDecoration(labelText: 'Colour')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;

    final payload = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      'brand': brandController.text.trim().isEmpty ? null : brandController.text.trim(),
      'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
      'size': sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
      'colour': colourController.text.trim().isEmpty ? null : colourController.text.trim(),
      'user_id': userId,
    };

    if (item == null) {
      await _service.createItem(payload);
    } else {
      await _service.updateItem(item['id'] as String, payload);
    }
    await _load();
  }

  Future<void> _deleteItem(String id) async {
    await _service.deleteItem(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      final term = _searchController.text.toLowerCase();
      return term.isEmpty ||
          (item['title'] as String).toLowerCase().contains(term) ||
          (item['brand'] as String? ?? '').toLowerCase().contains(term);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Items', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by title or brand'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SectionCard(
                  title: 'Items',
                  child: ScrollableDataTable(
                    table: DataTable(
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Brand')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Colour')),
                        DataColumn(label: Text('Created At')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredItems
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(Text(item['title'] ?? '')),
                                DataCell(Text(item['brand'] ?? '')),
                                DataCell(Text(item['category'] ?? '')),
                                DataCell(Text(item['size'] ?? '')),
                                DataCell(Text(item['colour'] ?? '')),
                                DataCell(Text(DateFormat.yMMMd().format(DateTime.parse(item['created_at'] as String)))),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _openItemDialog(item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteItem(item['id'] as String),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
