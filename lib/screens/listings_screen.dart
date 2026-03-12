import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/scrollable_data_table.dart';
import '../widgets/section_card.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  static const _platforms = ['Vinted', 'Depop', 'eBay', 'Tilt'];
  static const _statuses = ['Active', 'Sold', 'Ended'];

  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _listings = [];
  String? _platformFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _service = SupabaseService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.fetchItems(userId),
      _service.fetchListings(userId),
    ]);
    setState(() {
      _items = results[0];
      _listings = results[1];
      _loading = false;
    });
  }

  Future<void> _openListingDialog({Map<String, dynamic>? listing}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    String? selectedItemId = listing?['item_id'] as String?;
    String? selectedPlatform = listing?['platform'] as String?;
    String? selectedStatus = listing?['status'] as String? ?? 'Active';
    final priceController = TextEditingController(text: '${listing?['listed_price'] ?? ''}');
    final sourceUrlController = TextEditingController(text: listing?['source_url'] as String? ?? '');
    DateTime listedDate = listing?['listed_date'] == null
        ? DateTime.now()
        : DateTime.tryParse(listing!['listed_date'] as String) ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(listing == null ? 'Add Listing' : 'Edit Listing'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedItemId,
                    decoration: const InputDecoration(labelText: 'Item'),
                    items: _items
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['id'] as String,
                            child: Text(item['title'] as String? ?? 'Untitled item'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setModalState(() => selectedItemId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPlatform,
                    decoration: const InputDecoration(labelText: 'Platform'),
                    items: _platforms
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setModalState(() => selectedPlatform = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Listed Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statuses
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setModalState(() => selectedStatus = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sourceUrlController,
                    decoration: const InputDecoration(labelText: 'Source URL'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(DateFormat.yMMMd().format(listedDate)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: listedDate,
                          );
                          if (picked != null) {
                            setModalState(() => listedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: const Text('Listed date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != true || selectedItemId == null || selectedPlatform == null) return;

    final payload = {
      'item_id': selectedItemId,
      'platform': selectedPlatform,
      'listed_price': num.tryParse(priceController.text) ?? 0,
      'listed_date': listedDate.toIso8601String().substring(0, 10),
      'status': selectedStatus ?? 'Active',
      'source_url': sourceUrlController.text.trim().isEmpty ? null : sourceUrlController.text.trim(),
      'user_id': userId,
    };

    if (listing == null) {
      await _service.createListing(payload);
      _showToast('Listing created');
    } else {
      await _service.updateListing(listing['id'] as String, payload);
      _showToast('Listing updated');
    }
    await _load();
  }

  Future<void> _markAsSold(Map<String, dynamic> listing) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _service.createSale({
      'user_id': userId,
      'listing_id': listing['id'],
      'sale_price': listing['listed_price'],
      'sold_date': today,
      'fees': null,
      'shipping_cost': null,
    });
    await _service.updateListing(listing['id'] as String, {'status': 'Sold'});
    await _load();
    _showToast('Marked as sold');
  }

  Future<void> _deleteListing(String id) async {
    await _service.deleteListing(id);
    await _load();
    _showToast('Listing deleted');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _listings.where((listing) {
      final platformOk = _platformFilter == null || listing['platform'] == _platformFilter;
      final statusOk = _statusFilter == null || listing['status'] == _statusFilter;
      return platformOk && statusOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Listings', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openListingDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                value: _platformFilter,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ..._platforms.map((value) => DropdownMenuItem(value: value, child: Text(value))),
                ],
                onChanged: (value) => setState(() => _platformFilter = value),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                value: _statusFilter,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ..._statuses.map((value) => DropdownMenuItem(value: value, child: Text(value))),
                ],
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SectionCard(
                  title: 'Listings',
                  child: ScrollableDataTable(
                    table: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Platform')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Listed Price')),
                        DataColumn(label: Text('Listed Date')),
                        DataColumn(label: Text('Source')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: rows
                          .map(
                            (listing) => DataRow(
                              cells: [
                                DataCell(Text(listing['item']?['title'] as String? ?? '')),
                                DataCell(Text(listing['platform'] as String? ?? '')),
                                DataCell(Text(listing['status'] as String? ?? '')),
                                DataCell(Text(_currency(listing['listed_price'] as num? ?? 0))),
                                DataCell(Text(listing['listed_date'] as String? ?? '')),
                                DataCell(
                                  (listing['source_url'] as String?)?.isNotEmpty == true
                                      ? SelectableText(listing['source_url'] as String)
                                      : const Text('None'),
                                ),
                                DataCell(
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _openListingDialog(listing: listing),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.sell_outlined),
                                        onPressed: listing['status'] == 'Sold'
                                            ? null
                                            : () => _markAsSold(listing),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteListing(listing['id'] as String),
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
