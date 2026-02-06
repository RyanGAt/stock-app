import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/scrollable_data_table.dart';
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
  List<Map<String, dynamic>> _purchaseOrders = [];
  List<Map<String, dynamic>> _purchaseDetails = [];
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
      _service.fetchPurchaseOrders(userId),
      _service.fetchPurchaseDetails(userId),
      _service.fetchItems(userId),
    ]);
    setState(() {
      _purchaseOrders = results[0];
      _purchaseDetails = results[1];
      _items = results[2];
      _loading = false;
    });
  }

  Future<void> _openPurchaseOrderDialog({Map<String, dynamic>? purchase}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final totalPriceController = TextEditingController(text: purchase?['total_price']?.toString() ?? '');
    DateTime? boughtDate = purchase?['bought_date'] == null
        ? null
        : DateTime.parse(purchase?['bought_date'] as String);
    DateTime? arrivedDate = purchase?['arrived_date'] == null
        ? null
        : DateTime.parse(purchase?['arrived_date'] as String);
    final detailQtyController = TextEditingController(text: '1');
    final detailPriceController = TextEditingController(text: '');
    final detailSizeController = TextEditingController(text: '');
    final draftDetails = purchase == null
        ? <Map<String, dynamic>>[]
        : _purchaseDetails
            .where((row) => row['purchase_id'] == purchase['id'])
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
    final deletedDetailIds = <String>[];
    String? selectedDetailItemId = draftDetails.isNotEmpty
        ? draftDetails.first['item_id'] as String?
        : _items.firstOrNull?['id'] as String?;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(purchase == null ? 'Add Purchase' : 'Edit Purchase'),
          insetPadding: const EdgeInsets.all(24),
          content: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : 720.0;
              final maxDialogWidth = math.min(availableWidth, 720.0);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxDialogWidth),
                  child: SizedBox(
                    width: maxDialogWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  TextField(
                    controller: totalPriceController,
                    decoration: const InputDecoration(labelText: 'Total Price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        child: Text(
                          boughtDate == null ? 'Bought date not set' : DateFormat.yMMMd().format(boughtDate!),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDate: boughtDate ?? DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => boughtDate = picked);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: const Text('Pick Bought Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        child: Text(
                          arrivedDate == null ? 'Arrived date not set' : DateFormat.yMMMd().format(arrivedDate!),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: arrivedDate ?? boughtDate ?? DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => arrivedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.event_available),
                        label: const Text('Pick Arrived Date'),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Purchase Details', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 320,
                        child: DropdownButtonFormField<String>(
                          value: selectedDetailItemId,
                          decoration: const InputDecoration(labelText: 'Item'),
                          items: _items
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item['id'] as String,
                                  child: Text(item['title'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setModalState(() => selectedDetailItemId = value),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: detailSizeController,
                          decoration: const InputDecoration(labelText: 'Size'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: detailQtyController,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: detailPriceController,
                          decoration: const InputDecoration(labelText: 'Unit Price'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: selectedDetailItemId == null
                              ? null
                              : () {
                                  final item = _items.firstWhere(
                                    (item) => item['id'] == selectedDetailItemId,
                                    orElse: () => {},
                                  );
                                  final sizeValue = detailSizeController.text.trim();
                                  setModalState(() {
                                    draftDetails.add({
                                      'item_id': selectedDetailItemId,
                                      'items': item,
                                      'size': sizeValue.isEmpty ? null : sizeValue,
                                      'quantity': int.tryParse(detailQtyController.text) ?? 1,
                                      'unit_price': num.tryParse(detailPriceController.text) ?? 0,
                                    });
                                    detailQtyController.text = '1';
                                    detailPriceController.clear();
                                    detailSizeController.clear();
                                  });
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Add detail'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: draftDetails.isEmpty
                        ? const Center(child: Text('No details added yet.'))
                        : ScrollableDataTable(
                            table: DataTable(
                              columns: const [
                                DataColumn(label: Text('Item')),
                                DataColumn(label: Text('Size')),
                                DataColumn(label: Text('Qty')),
                                DataColumn(label: Text('Unit Price')),
                                DataColumn(label: Text('Line Total')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: draftDetails
                                  .map(
                                    (detail) => DataRow(
                                      cells: [
                                        DataCell(Text(detail['items']?['title'] ?? '')),
                                        DataCell(Text(detail['size'] ?? '')),
                                        DataCell(Text('${detail['quantity']}')),
                                        DataCell(Text(_currency(detail['unit_price'] as num? ?? 0))),
                                        DataCell(Text(_currency(
                                            (detail['unit_price'] as num? ?? 0) *
                                                (detail['quantity'] as int)))),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              final id = detail['id'] as String?;
                                              if (id != null) {
                                                deletedDetailIds.add(id);
                                              }
                                              setModalState(() => draftDetails.remove(detail));
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != true) {
      totalPriceController.dispose();
      detailQtyController.dispose();
      detailPriceController.dispose();
      detailSizeController.dispose();
      return;
    }

    final payload = {
      'user_id': userId,
      'total_price': num.tryParse(totalPriceController.text) ?? 0,
      'bought_date': boughtDate?.toIso8601String(),
      'arrived_date': arrivedDate?.toIso8601String(),
    };

    if (purchase == null) {
      final createdPurchase = await _service.createPurchaseOrder(payload);
      final purchaseId = createdPurchase['id'] as String?;
      if (purchaseId != null) {
        for (final detail in draftDetails) {
          await _service.createPurchaseDetail({
            'purchase_id': purchaseId,
            'item_id': detail['item_id'],
            'user_id': userId,
            'quantity': detail['quantity'] as int? ?? 1,
            'unit_price': detail['unit_price'] as num? ?? 0,
            'size': detail['size'],
          });
        }
      }
    } else {
      final purchaseId = purchase['id'] as String;
      await _service.updatePurchaseOrder(purchase['id'] as String, payload);
      for (final id in deletedDetailIds) {
        await _service.deletePurchaseDetail(id);
      }
      for (final detail in draftDetails) {
        if (detail['id'] != null) continue;
        await _service.createPurchaseDetail({
          'purchase_id': purchaseId,
          'item_id': detail['item_id'],
          'user_id': userId,
          'quantity': detail['quantity'] as int? ?? 1,
          'unit_price': detail['unit_price'] as num? ?? 0,
          'size': detail['size'],
        });
      }
    }
    await _load();
    totalPriceController.dispose();
    detailQtyController.dispose();
    detailPriceController.dispose();
    detailSizeController.dispose();
  }

  Future<void> _openPurchaseDetailDialog({Map<String, dynamic>? detail}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final qtyController = TextEditingController(text: detail?['quantity']?.toString() ?? '1');
    final priceController = TextEditingController(text: detail?['unit_price']?.toString() ?? '');
    final sizeController = TextEditingController(text: detail?['size'] ?? '');
    String? selectedItemId = detail?['item_id'] as String? ?? _items.firstOrNull?['id'] as String?;
    String? selectedPurchaseId =
        detail?['purchase_id'] as String? ?? _purchaseOrders.firstOrNull?['id'] as String?;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(detail == null ? 'Add Purchase Item' : 'Edit Purchase Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPurchaseId,
                decoration: const InputDecoration(labelText: 'Purchase'),
                items: _purchaseOrders
                    .map(
                      (purchase) => DropdownMenuItem(
                        value: purchase['id'] as String,
                        child: Text(_purchaseLabel(purchase)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedPurchaseId = value,
              ),
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
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true || selectedItemId == null || selectedPurchaseId == null) return;

    final payload = {
      'purchase_id': selectedPurchaseId,
      'item_id': selectedItemId,
      'user_id': userId,
      'quantity': int.tryParse(qtyController.text) ?? 1,
      'unit_price': num.tryParse(priceController.text) ?? 0,
      'size': sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
    };

    if (detail == null) {
      await _service.createPurchaseDetail(payload);
    } else {
      await _service.updatePurchaseDetail(detail['id'] as String, payload);
    }
    await _load();
  }

  Future<void> _addToStock(Map<String, dynamic> detail) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _service.upsertItemStock({
      'item_id': detail['item_id'],
      'user_id': userId,
      'quantity': detail['quantity'],
      'size': detail['size'],
    });
    await _service.updatePurchaseDetail(detail['id'] as String, {'added_to_stock': true});
    await _load();
  }

  Future<void> _deletePurchaseOrder(String id) async {
    await _service.deletePurchaseOrder(id);
    await _load();
  }

  Future<void> _deletePurchaseDetail(String id) async {
    await _service.deletePurchaseDetail(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpend = _purchaseDetails.fold<num>(
      0,
      (sum, row) => sum + (row['unit_price'] as num) * (row['quantity'] as int),
    );
    final totalUnits = _purchaseDetails.fold<int>(0, (sum, row) => sum + (row['quantity'] as int));
    final avgCost = totalUnits == 0 ? 0 : totalSpend / totalUnits;
    final distinctItems = _purchaseDetails.map((row) => row['item_id']).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Purchase History', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openPurchaseOrderDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Purchase'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _purchaseOrders.isEmpty ? null : () => _openPurchaseDetailDialog(),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add Purchase Item'),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;
                      final tableHeight = (maxHeight - 24) / 2;
                      return Column(
                        children: [
                          SizedBox(
                            height: tableHeight,
                            child: ScrollableDataTable(
                              table: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Total Price')),
                                  DataColumn(label: Text('Bought Date')),
                                  DataColumn(label: Text('Arrived Date')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _purchaseOrders
                                    .map(
                                      (purchase) => DataRow(
                                        cells: [
                                          DataCell(Text(_currency(purchase['total_price'] as num? ?? 0))),
                                          DataCell(Text(purchase['bought_date'] ?? '')),
                                          DataCell(Text(purchase['arrived_date'] ?? '')),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () => _openPurchaseOrderDialog(purchase: purchase),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete),
                                                  onPressed: () => _deletePurchaseOrder(purchase['id'] as String),
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
                          const SizedBox(height: 24),
                          SizedBox(
                            height: tableHeight,
                            child: ScrollableDataTable(
                              table: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Purchase')),
                                  DataColumn(label: Text('Item')),
                                  DataColumn(label: Text('Brand')),
                                  DataColumn(label: Text('Size')),
                                  DataColumn(label: Text('Qty')),
                                  DataColumn(label: Text('Unit Price')),
                                  DataColumn(label: Text('Line Total')),
                                  DataColumn(label: Text('Stock')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _purchaseDetails
                                    .map(
                                      (detail) => DataRow(
                                        cells: [
                                          DataCell(Text(_purchaseLabel(detail['purchases']))),
                                          DataCell(Text(detail['items']?['title'] ?? '')),
                                          DataCell(Text(detail['items']?['brand'] ?? '')),
                                          DataCell(Text(detail['size'] ?? '')),
                                          DataCell(Text('${detail['quantity']}')),
                                          DataCell(Text(_currency(detail['unit_price'] as num))),
                                          DataCell(Text(_currency(
                                              (detail['unit_price'] as num) * (detail['quantity'] as int)))),
                                          DataCell(
                                            detail['added_to_stock'] == true
                                                ? const Text('Added')
                                                : TextButton(
                                                    onPressed: () => _addToStock(detail),
                                                    child: const Text('Add to stock'),
                                                  ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () => _openPurchaseDetailDialog(detail: detail),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete),
                                                  onPressed: () => _deletePurchaseDetail(detail['id'] as String),
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
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

String _currency(num value) => NumberFormat.currency(symbol: '£').format(value);

String _purchaseLabel(Map<String, dynamic>? purchase) {
  if (purchase == null) return 'Purchase';
  final boughtDate = purchase['bought_date'] as String?;
  final formattedDate = boughtDate == null ? 'No date' : boughtDate;
  final totalPrice = purchase['total_price'] as num? ?? 0;
  return '$formattedDate • ${_currency(totalPrice)}';
}

extension on List {
  dynamic get firstOrNull => isEmpty ? null : first;
}
