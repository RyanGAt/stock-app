import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/scrollable_data_table.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _stock = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _purchaseDetails = [];
  List<Map<String, dynamic>> _costs = [];

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
      _service.fetchItemStock(userId),
      _service.fetchItems(userId),
      _service.fetchPurchaseDetails(userId),
      _service.fetchItemCosts(userId),
    ]);
    setState(() {
      _stock = results[0];
      _items = results[1];
      _purchaseDetails = results[2];
      _costs = results[3];
      _loading = false;
    });
  }

  Future<void> _openManageDialog(String itemId) async {
    final itemStock = _stock.where((row) => row['item_id'] == itemId).toList();
    final itemPurchases = _purchaseDetails.where((row) => row['item_id'] == itemId).toList();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Stock'),
        content: SizedBox(
          width: 600,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(tabs: [
                  Tab(text: 'Adjust Stock'),
                  Tab(text: 'Purchase History'),
                ]),
                SizedBox(
                  height: 360,
                  child: TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: itemStock.length,
                        itemBuilder: (context, index) {
                          final row = itemStock[index];
                          final controller = TextEditingController(text: row['quantity'].toString());
                          return ListTile(
                            title: Text(row['size'] ?? 'One Size'),
                            subtitle: Text('Available: ${row['quantity']}'),
                            trailing: SizedBox(
                              width: 120,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Qty'),
                                onSubmitted: (value) async {
                                  await _service.updateItemStock(
                                    row['id'] as String,
                                    {'quantity': int.tryParse(value) ?? row['quantity']},
                                  );
                                  await _load();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: itemPurchases.length,
                        itemBuilder: (context, index) {
                          final purchase = itemPurchases[index];
                          final purchaseDate = purchase['purchases']?['bought_date'] as String?;
                          return ListTile(
                            title: Text('Qty ${purchase['quantity']} @ ${_currency(purchase['unit_price'] as num)}'),
                            subtitle: Text(purchaseDate ?? 'No date'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await _service.deletePurchaseDetail(purchase['id'] as String);
                                await _load();
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = _stock.fold<int>(0, (sum, row) => sum + (row['quantity'] as int));
    final itemsInStock = _stock.map((row) => row['item_id']).toSet().length;
    final inventoryCost = _costs.fold<num>(
      0,
      (sum, cost) => sum + (cost['avg_unit_cost'] as num? ?? 0) * (cost['total_purchased_qty'] as int? ?? 0),
    );
    final totalSpend = _purchaseDetails.fold<num>(
      0,
      (sum, row) => sum + (row['unit_price'] as num) * (row['quantity'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stock', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 720
                ? 1
                : constraints.maxWidth < 1100
                    ? 2
                    : 4;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: 2.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'Items in Stock', value: itemsInStock.toString()),
                StatCard(label: 'Total Units', value: totalUnits.toString()),
                StatCard(label: 'Inventory Cost', value: _currency(inventoryCost)),
                StatCard(label: 'Total Spend', value: _currency(totalSpend)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SectionCard(
                  title: 'Stock',
                  child: ScrollableDataTable(
                    minWidth: 1180,
                    table: DataTable(
                      columns: const [
                        DataColumn(label: Text('Image')),
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Sizes')),
                        DataColumn(label: Text('Avg Cost')),
                        DataColumn(label: Text('Total Qty')),
                        DataColumn(label: Text('Available')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _items
                          .map(
                            (item) {
                              final itemStock = _stock.where((row) => row['item_id'] == item['id']).toList();
                              if (itemStock.isEmpty) return null;
                              final avgCost = _costs
                                      .firstWhere(
                                        (cost) => cost['item_id'] == item['id'],
                                        orElse: () => {'avg_unit_cost': 0},
                                      )['avg_unit_cost'] as num? ??
                                  0;
                              final totalQty = itemStock.fold<int>(0, (sum, row) => sum + (row['quantity'] as int));
                              return DataRow(
                                cells: [
                                  DataCell(item['main_image_url'] == null
                                      ? const Icon(Icons.image_not_supported)
                                      : Image.network(item['main_image_url'],
                                          width: 40, height: 40, fit: BoxFit.cover)),
                                  DataCell(Text(item['title'] ?? '')),
                                  DataCell(
                                    Wrap(
                                      spacing: 8,
                                      children: itemStock
                                          .map((row) => Chip(label: Text('${row['size'] ?? 'OS'}: ${row['quantity']}')))
                                          .toList(),
                                    ),
                                  ),
                                  DataCell(Text(_currency(avgCost))),
                                  DataCell(Text(totalQty.toString())),
                                  DataCell(Text(totalQty.toString())),
                                  DataCell(
                                    TextButton(
                                      onPressed: () => _openManageDialog(item['id'] as String),
                                      child: const Text('Manage'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                          .whereType<DataRow>()
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
