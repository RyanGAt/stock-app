import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _items = [];

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
      _service.fetchPurchases(userId),
      _service.fetchItems(userId),
    ]);
    setState(() {
      _purchases = results[0];
      _items = results[1];
      _loading = false;
    });
  }

  Future<void> _openPurchaseDialog({Map<String, dynamic>? purchase}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final qtyController = TextEditingController(text: purchase?['quantity']?.toString() ?? '1');
    final priceController = TextEditingController(text: purchase?['unit_price']?.toString() ?? '');
    final sizeController = TextEditingController(text: purchase?['size'] ?? '');
    DateTime? purchasedAt = purchase?['purchased_at'] == null
        ? null
        : DateTime.parse(purchase?['purchased_at'] as String);
    String? selectedItemId = purchase?['item_id'] as String? ?? _items.firstOrNull?['id'] as String?;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(purchase == null ? 'Add Purchase' : 'Edit Purchase'),
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
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: 'Size'),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(purchasedAt == null
                        ? 'Purchased date not set'
                        : DateFormat.yMMMd().format(purchasedAt!)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: purchasedAt ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => purchasedAt = picked);
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
      'quantity': int.tryParse(qtyController.text) ?? 1,
      'unit_price': num.tryParse(priceController.text) ?? 0,
      'purchased_at': purchasedAt?.toIso8601String(),
      'size': sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
    };

    if (purchase == null) {
      await _service.createPurchase(payload);
    } else {
      await _service.updatePurchase(purchase['id'] as String, payload);
    }
    await _load();
  }

  Future<void> _addToStock(Map<String, dynamic> purchase) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _service.upsertItemStock({
      'item_id': purchase['item_id'],
      'user_id': userId,
      'quantity': purchase['quantity'],
      'size': purchase['size'],
    });
    await _service.updatePurchase(purchase['id'] as String, {'added_to_stock': true});
    await _load();
  }

  Future<void> _deletePurchase(String id) async {
    await _service.deletePurchase(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpend = _purchases.fold<num>(
      0,
      (sum, row) => sum + (row['unit_price'] as num) * (row['quantity'] as int),
    );
    final totalUnits = _purchases.fold<int>(0, (sum, row) => sum + (row['quantity'] as int));
    final avgCost = totalUnits == 0 ? 0 : totalSpend / totalUnits;
    final distinctItems = _purchases.map((row) => row['item_id']).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Purchase History', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openPurchaseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Purchase'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          childAspectRatio: 2.6,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(label: 'Total Spend', value: _currency(totalSpend)),
            StatCard(label: 'Total Units Purchased', value: totalUnits.toString()),
            StatCard(label: 'Avg Cost / Unit', value: _currency(avgCost)),
            StatCard(label: 'Distinct Items', value: distinctItems.toString()),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SectionCard(
                  title: 'Purchases',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Brand')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Unit Price')),
                        DataColumn(label: Text('Line Total')),
                        DataColumn(label: Text('Purchased At')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _purchases
                          .map(
                            (purchase) => DataRow(
                              cells: [
                                DataCell(Text(purchase['items']?['title'] ?? '')),
                                DataCell(Text(purchase['items']?['brand'] ?? '')),
                                DataCell(Text(purchase['size'] ?? '')),
                                DataCell(Text('${purchase['quantity']}')),
                                DataCell(Text(_currency(purchase['unit_price'] as num))),
                                DataCell(Text(_currency((purchase['unit_price'] as num) * (purchase['quantity'] as int)))),
                                DataCell(Text(purchase['purchased_at'] ?? '')),
                                DataCell(
                                  purchase['added_to_stock'] == true
                                      ? const Text('Added')
                                      : TextButton(
                                          onPressed: () => _addToStock(purchase),
                                          child: const Text('Add to stock'),
                                        ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _openPurchaseDialog(purchase: purchase),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deletePurchase(purchase['id'] as String),
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

extension on List {
  dynamic get firstOrNull => isEmpty ? null : first;
}
