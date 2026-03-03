import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';

class StockPage extends HookConsumerWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockProvider);
    final branch = ref.watch(branchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Available - ${branch?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(stockProvider),
          ),
        ],
      ),
      body: stockAsync.when(
        data: (stockItems) {
          if (stockItems.isEmpty) {
            return const Center(child: Text('No stock data found.'));
          }

          final totalStock = stockItems.length;
          final availableStock = stockItems
              .where((s) => s.status.toLowerCase() == 'available')
              .length;
          final blockedStock = stockItems
              .where((s) => s.status.toLowerCase() == 'blocked')
              .length;

          // Process model-wise count
          final Map<String, int> modelCounts = {};
          for (var stock in stockItems) {
            if (stock.status.toLowerCase() == 'available' ||
                stock.status.toLowerCase() == 'in transit') {
              modelCounts[stock.vehicleModel] =
                  (modelCounts[stock.vehicleModel] ?? 0) + 1;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context,
                      'Total Inventory',
                      totalStock.toString(),
                      Icons.inventory_2,
                    ),
                    _buildStatCard(
                      context,
                      'Available',
                      availableStock.toString(),
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Blocked',
                      blockedStock.toString(),
                      Icons.lock_outline,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (modelCounts.isNotEmpty) ...[
                  Text(
                    'Model Wise Available/Transit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: modelCounts.entries.map((e) {
                      return Chip(
                        label: Text('${e.key}: ${e.value}'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Detailed Inventory',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Vehicle Model')),
                      DataColumn(label: Text('Color')),
                      DataColumn(label: Text('Chassis Number')),
                      DataColumn(label: Text('Engine Number')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Days In Stock')),
                    ],
                    rows: stockItems.map((stock) {
                      return DataRow(
                        cells: [
                          DataCell(Text(stock.vehicleModel)),
                          DataCell(Text(stock.color)),
                          DataCell(Text(stock.chassisNumber)),
                          DataCell(Text(stock.engineNumber)),
                          DataCell(Text(stock.location)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  stock.status,
                                ).withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(stock.status),
                                ),
                              ),
                              child: Text(
                                stock.status,
                                style: TextStyle(
                                  color: _getStatusColor(stock.status),
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(stock.daysInStock.toString())),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'blocked':
        return Colors.orange;
      case 'in transit':
        return Colors.blue;
      case 'sold':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
