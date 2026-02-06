import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final service = SupabaseService(Supabase.instance.client);
    return FutureBuilder<DashboardData>(
      future: _loadDashboard(service, user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 2.4,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(label: 'Total Items', value: data.totalItems.toString()),
                  StatCard(label: 'Active Listings', value: data.activeListings.toString()),
                  StatCard(label: 'Total Sales', value: data.totalSales.toString()),
                  StatCard(label: 'Inventory Cost', value: _currency(data.inventoryCost)),
                  StatCard(label: 'Total Revenue', value: _currency(data.totalRevenue)),
                  StatCard(label: 'Total Profit', value: _currency(data.totalProfit)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SectionCard(
                      title: 'Recent Sales',
                      child: _SalesTable(rows: data.recentSales),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SectionCard(
                      title: 'Active Listings',
                      child: _ListingsTable(rows: data.activeListingRows),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _currency(num value) => NumberFormat.currency(symbol: '£').format(value);

Future<DashboardData> _loadDashboard(SupabaseService service, String userId) async {
  final items = await service.fetchItems(userId);
  final listings = await service.fetchListings(userId);
  final sales = await service.fetchSales(userId);
  final itemCosts = await service.fetchItemCosts(userId);

  final activeListings = listings.where((listing) => listing['status'] == 'Active').toList();
  final totalRevenue = sales.fold<num>(
    0,
    (sum, row) => sum + (row['sale_price'] as num? ?? 0),
  );
  final totalProfit = sales.fold<num>(0, (sum, row) {
    final salePrice = row['sale_price'] as num? ?? 0;
    final fees = row['fees'] as num? ?? 0;
    final shipping = row['shipping_cost'] as num? ?? 0;
    final itemId = row['item_id'] as String?;
    final avgCost = itemCosts
            .firstWhere(
              (cost) => cost['item_id'] == itemId,
              orElse: () => {'avg_unit_cost': 0},
            )['avg_unit_cost'] as num? ??
        0;
    return sum + (salePrice - fees - shipping - avgCost);
  });

  final inventoryCost = itemCosts.fold<num>(
    0,
    (sum, cost) => sum + (cost['avg_unit_cost'] as num? ?? 0) * (cost['total_purchased_qty'] as int? ?? 0),
  );

  return DashboardData(
    totalItems: items.length,
    activeListings: activeListings.length,
    totalSales: sales.length,
    totalRevenue: totalRevenue,
    totalProfit: totalProfit,
    inventoryCost: inventoryCost,
    recentSales: sales.take(5).toList(),
    activeListingRows: activeListings.take(5).toList(),
  );
}

class DashboardData {
  DashboardData({
    required this.totalItems,
    required this.activeListings,
    required this.totalSales,
    required this.totalRevenue,
    required this.totalProfit,
    required this.inventoryCost,
    required this.recentSales,
    required this.activeListingRows,
  });

  final int totalItems;
  final int activeListings;
  final int totalSales;
  final num totalRevenue;
  final num totalProfit;
  final num inventoryCost;
  final List<Map<String, dynamic>> recentSales;
  final List<Map<String, dynamic>> activeListingRows;
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Platform')),
            DataColumn(label: Text('Sale Price')),
            DataColumn(label: Text('Sold Date')),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row['items']?['title'] ?? '')),
                    DataCell(Text(row['platform'] ?? '')),
                    DataCell(Text(_currency(row['sale_price'] as num? ?? 0))),
                    DataCell(Text(row['sold_date'] ?? '')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ListingsTable extends StatelessWidget {
  const _ListingsTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Platform')),
            DataColumn(label: Text('Listed Price')),
            DataColumn(label: Text('Listed Date')),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row['items']?['title'] ?? '')),
                    DataCell(Text(row['platform'] ?? '')),
                    DataCell(Text(_currency(row['listed_price'] as num? ?? 0))),
                    DataCell(Text(row['listed_date'] ?? '')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
