import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _stock = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _costs = [];

  String _platformFilter = 'All';
  String _timeframe = 'All';

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
      _service.fetchSales(userId),
      _service.fetchItemStock(userId),
      _service.fetchItems(userId),
      _service.fetchItemCosts(userId),
    ]);
    setState(() {
      _sales = results[0];
      _stock = results[1];
      _items = results[2];
      _costs = results[3];
      _loading = false;
    });
  }

  Future<void> _openSaleDialog({Map<String, dynamic>? sale}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    String? selectedItemId = sale?['item_id'] as String?;
    String? selectedSize = sale?['size'] as String?;
    DateTime? soldDate = sale?['sold_date'] == null
        ? null
        : DateTime.parse(sale?['sold_date'] as String);

    final platformController = TextEditingController(text: sale?['platform'] ?? '');
    final priceController = TextEditingController(text: sale?['sale_price']?.toString() ?? '');
    final feesController = TextEditingController(text: sale?['fees']?.toString() ?? '');
    final shippingController = TextEditingController(text: sale?['shipping_cost']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sale == null ? 'Add Sale' : 'Edit Sale'),
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
                onChanged: (value) {
                  selectedItemId = value;
                },
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
                decoration: const InputDecoration(labelText: 'Sale Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: feesController,
                decoration: const InputDecoration(labelText: 'Fees'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: shippingController,
                decoration: const InputDecoration(labelText: 'Shipping'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(soldDate == null
                        ? 'Sold date not set'
                        : DateFormat.yMMMd().format(soldDate!)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: soldDate ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => soldDate = picked);
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
      'sale_price': num.tryParse(priceController.text) ?? 0,
      'fees': num.tryParse(feesController.text) ?? 0,
      'shipping_cost': num.tryParse(shippingController.text) ?? 0,
      'sold_date': soldDate?.toIso8601String(),
    };

    if (sale == null) {
      await _service.createSale(payload);
    } else {
      await _service.updateSale(sale['id'] as String, payload);
    }
    await _load();
  }

  Future<void> _deleteSale(String id) async {
    await _service.deleteSale(id);
    await _load();
  }

  List<Map<String, dynamic>> _filteredSales() {
    final now = DateTime.now();
    return _sales.where((sale) {
      if (_platformFilter != 'All' && sale['platform'] != _platformFilter) {
        return false;
      }
      final soldDate = sale['sold_date'] == null ? null : DateTime.parse(sale['sold_date'] as String);
      if (_timeframe == 'Daily' && soldDate != null) {
        return soldDate.isAfter(now.subtract(const Duration(days: 1)));
      }
      if (_timeframe == 'Weekly' && soldDate != null) {
        return soldDate.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (_timeframe == 'Monthly' && soldDate != null) {
        return soldDate.isAfter(now.subtract(const Duration(days: 30)));
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _filteredSales();
    final totalRevenue = filteredSales.fold<num>(
      0,
      (sum, row) => sum + (row['sale_price'] as num? ?? 0),
    );
    final totalProfit = filteredSales.fold<num>(0, (sum, row) {
      final salePrice = row['sale_price'] as num? ?? 0;
      final fees = row['fees'] as num? ?? 0;
      final shipping = row['shipping_cost'] as num? ?? 0;
      final itemId = row['item_id'] as String?;
      final avgCost = _costs
              .firstWhere(
                (cost) => cost['item_id'] == itemId,
                orElse: () => {'avg_unit_cost': 0},
              )['avg_unit_cost'] as num? ??
          0;
      return sum + (salePrice - fees - shipping - avgCost);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Sales', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openSaleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Sale'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          childAspectRatio: 2.6,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(label: 'Total Revenue', value: _currency(totalRevenue)),
            StatCard(label: 'Total Profit', value: _currency(totalProfit)),
            StatCard(label: 'Number of Sales', value: filteredSales.length.toString()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            DropdownButton<String>(
              value: _platformFilter,
              items: ['All', ..._sales.map((row) => row['platform'] ?? '').where((p) => p != '').toSet()]
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _platformFilter = value ?? 'All'),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _timeframe,
              items: const ['All', 'Daily', 'Weekly', 'Monthly']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _timeframe = value ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SectionCard(
                  title: 'Sales',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Platform')),
                        DataColumn(label: Text('Sale Price')),
                        DataColumn(label: Text('Fees')),
                        DataColumn(label: Text('Shipping')),
                        DataColumn(label: Text('Sold Date')),
                        DataColumn(label: Text('Profit')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredSales
                          .map(
                            (sale) {
                              final item = _items.firstWhere(
                                (item) => item['id'] == sale['item_id'],
                                orElse: () => {},
                              );
                              final avgCost = _costs
                                      .firstWhere(
                                        (cost) => cost['item_id'] == sale['item_id'],
                                        orElse: () => {'avg_unit_cost': 0},
                                      )['avg_unit_cost'] as num? ??
                                  0;
                              final profit = (sale['sale_price'] as num? ?? 0) -
                                  (sale['fees'] as num? ?? 0) -
                                  (sale['shipping_cost'] as num? ?? 0) -
                                  avgCost;
                              return DataRow(
                                cells: [
                                  DataCell(Text(item['title'] ?? '')),
                                  DataCell(Text(sale['size'] ?? '')),
                                  DataCell(Text(sale['platform'] ?? '')),
                                  DataCell(Text(_currency(sale['sale_price'] as num? ?? 0))),
                                  DataCell(Text(_currency(sale['fees'] as num? ?? 0))),
                                  DataCell(Text(_currency(sale['shipping_cost'] as num? ?? 0))),
                                  DataCell(Text(sale['sold_date'] ?? '')),
                                  DataCell(Text(_currency(profit))),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _openSaleDialog(sale: sale),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteSale(sale['id'] as String),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
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
