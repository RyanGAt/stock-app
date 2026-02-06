import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/section_card.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _stock = [];

  String _platformFilter = 'All';
  String _statusFilter = 'All';

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
      _service.fetchListings(userId),
      _service.fetchItems(userId),
      _service.fetchItemStock(userId),
    ]);
    setState(() {
      _listings = results[0];
      _items = results[1];
      _stock = results[2];
      _loading = false;
    });
  }

  Future<void> _openListingDialog({Map<String, dynamic>? listing}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    String? selectedItemId = listing?['item_id'] as String?;
    String? selectedSize = listing?['size'] as String?;
    DateTime? listedDate = listing?['listed_date'] == null
        ? null
        : DateTime.parse(listing?['listed_date'] as String);

    final platformController = TextEditingController(text: listing?['platform'] ?? '');
    final priceController = TextEditingController(text: listing?['listed_price']?.toString() ?? '');
    final statusController = TextEditingController(text: listing?['status'] ?? 'Active');
    final sourceController = TextEditingController(text: listing?['source_url'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(listing == null ? 'Add Listing' : 'Edit Listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedItemId,
                decoration: const InputDecoration(labelText: 'Item'),
                items: _items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['id'] as String,
                        child: Text(item['title'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedItemId = value,
              ),
              DropdownButtonFormField<String>(
                value: selectedSize,
                decoration: const InputDecoration(labelText: 'Size'),
                items: _stock
                    .where((row) => row['item_id'] == selectedItemId)
                    .map(
                      (row) => DropdownMenuItem(
                        value: row['size'] as String?,
                        child: Text(row['size'] ?? 'OS'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedSize = value,
              ),
              TextField(
                controller: platformController,
                decoration: const InputDecoration(labelText: 'Platform'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Listed Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(labelText: 'Source URL'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(listedDate == null
                        ? 'Listed date not set'
                        : DateFormat.yMMMd().format(listedDate!)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: listedDate ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => listedDate = picked);
                      }
                    },
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true || selectedItemId == null) return;

    final payload = {
      'item_id': selectedItemId,
      'user_id': userId,
      'size': selectedSize,
      'platform': platformController.text.trim(),
      'listed_price': num.tryParse(priceController.text) ?? 0,
      'listed_date': listedDate?.toIso8601String(),
      'status': statusController.text.trim().isEmpty ? 'Active' : statusController.text.trim(),
      'source_url': sourceController.text.trim().isEmpty ? null : sourceController.text.trim(),
    };

    if (listing == null) {
      await _service.createListing(payload);
    } else {
      await _service.updateListing(listing['id'] as String, payload);
    }
    await _load();
  }

  Future<void> _importFromVinted() async {
    final urlController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Vinted'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(labelText: 'Vinted URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );

    if (result != true || urlController.text.trim().isEmpty) return;

    final data = await _service.importVinted(urlController.text.trim());
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imported Listing'),
        content: Text('Title: ${data['title'] ?? ''}\nBrand: ${data['brand'] ?? ''}\nPrice: ${data['listed_price'] ?? ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _markAsSold(Map<String, dynamic> listing) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _service.createSale({
      'user_id': userId,
      'item_id': listing['item_id'],
      'listing_id': listing['id'],
      'platform': listing['platform'],
      'sale_price': listing['listed_price'],
      'sold_date': DateTime.now().toIso8601String(),
    });
    await _service.updateListing(listing['id'] as String, {'status': 'Sold'});
    await _load();
  }

  List<Map<String, dynamic>> _filteredListings() {
    return _listings.where((listing) {
      if (_platformFilter != 'All' && listing['platform'] != _platformFilter) {
        return false;
      }
      if (_statusFilter != 'All' && listing['status'] != _statusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredListings = _filteredListings();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Listings', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            OutlinedButton(
              onPressed: _importFromVinted,
              child: const Text('Import from Vinted'),
            ),
            const SizedBox(width: 8),
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
            DropdownButton<String>(
              value: _platformFilter,
              items: ['All', ..._listings.map((row) => row['platform'] ?? '').where((p) => p != '').toSet()]
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _platformFilter = value ?? 'All'),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _statusFilter,
              items: const ['All', 'Active', 'Sold', 'Ended']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _statusFilter = value ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SectionCard(
                  title: 'Listings',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Platform')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Listed Price')),
                        DataColumn(label: Text('Listed Date')),
                        DataColumn(label: Text('Source URL')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredListings
                          .map(
                            (listing) => DataRow(
                              cells: [
                                DataCell(Text(listing['items']?['title'] ?? '')),
                                DataCell(Text(listing['size'] ?? '')),
                                DataCell(Text(listing['platform'] ?? '')),
                                DataCell(Text(listing['status'] ?? '')),
                                DataCell(Text(_currency(listing['listed_price'] as num? ?? 0))),
                                DataCell(Text(listing['listed_date'] ?? '')),
                                DataCell(Text(listing['source_url'] ?? '')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.sell),
                                        onPressed: listing['status'] == 'Active'
                                            ? () => _markAsSold(listing)
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _openListingDialog(listing: listing),
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

String _currency(num value) => NumberFormat.currency(symbol: '£').format(value);
