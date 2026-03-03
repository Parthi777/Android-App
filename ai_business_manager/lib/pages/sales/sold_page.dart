import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';

class SoldPage extends HookConsumerWidget {
  const SoldPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soldAsync = ref.watch(soldProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Sold Vehicles - ${branch?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(soldProvider),
          ),
        ],
      ),
      body: soldAsync.when(
        data: (soldItems) {
          if (soldItems.isEmpty) {
            return const Center(child: Text('No sold vehicles found.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Sale ID')),
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Vehicle Model')),
                  DataColumn(label: Text('Amount (₹)')),
                ],
                rows: soldItems.map((sold) {
                  return DataRow(
                    cells: [
                      DataCell(Text(dateFormat.format(sold.saleDate))),
                      DataCell(Text(sold.saleId)),
                      DataCell(Text(sold.customerName)),
                      DataCell(Text(sold.vehicleModel)),
                      DataCell(Text('₹${sold.saleAmount.toStringAsFixed(0)}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement Add Sold Item
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Sold Vehicle Coming Soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
