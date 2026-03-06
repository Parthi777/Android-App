import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';
import '../../utils/export_utils.dart';

import '../../models/sheet_data_models.dart';

class StockPage extends HookConsumerWidget {
  final List<Stock>? preFilterData;
  final String? drillDownTitle;

  const StockPage({super.key, this.preFilterData, this.drillDownTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Stock>> stockAsync = preFilterData != null
        ? AsyncData(preFilterData!)
        : ref.watch(stockProvider);
    final branch = ref.watch(branchProvider);
    final searchQuery = useState('');
    final selectedDateRange = useState<DateTimeRange?>(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          drillDownTitle ?? 'Stock Available - ${branch?.name ?? ''}',
        ),
        actions: [
          if (selectedDateRange.value != null)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () => selectedDateRange.value = null,
              tooltip: 'Clear Date Filter',
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: selectedDateRange.value,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (range != null) {
                selectedDateRange.value = range;
              }
            },
            tooltip: 'Filter by Date Range',
          ),
          if (preFilterData == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(stockProvider);
              },
              tooltip: 'Refresh Data',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onSelected: (value) async {
              final data = stockAsync.value ?? [];
              final filtered = data.where((s) {
                if (selectedDateRange.value != null) {
                  final start = selectedDateRange.value!.start;
                  final end = selectedDateRange.value!.end;
                  DateTime? parsedDate;
                  final formats = [
                    'dd MMM yyyy',
                    'dd-MM-yyyy',
                    'MM/dd/yyyy',
                    'yyyy-MM-dd',
                    'dd/MM/yyyy',
                  ];
                  for (var format in formats) {
                    try {
                      parsedDate = DateFormat(
                        format,
                      ).parseStrict(s.tvsInvoiceDate);
                      break;
                    } catch (_) {}
                  }
                  parsedDate ??= DateTime.tryParse(s.tvsInvoiceDate);

                  if (parsedDate != null) {
                    final d = DateTime(
                      parsedDate.year,
                      parsedDate.month,
                      parsedDate.day,
                    );
                    final st = DateTime(start.year, start.month, start.day);
                    final en = DateTime(end.year, end.month, end.day);
                    if (d.isBefore(st) || d.isAfter(en)) return false;
                  } else {
                    return false; // Skip if date cant be parsed and range is selected
                  }
                }
                if (searchQuery.value.isNotEmpty) {
                  final q = searchQuery.value.toLowerCase();
                  if (!s.vehicleModel.toLowerCase().contains(q) &&
                      !s.frameNo.toLowerCase().contains(q) &&
                      !s.engineNo.toLowerCase().contains(q) &&
                      !s.color.toLowerCase().contains(q)) {
                    return false;
                  }
                }
                return true;
              }).toList();

              final headers = [
                'Model',
                'Color',
                'Frame No',
                'Engine No',
                'Quantity',
                'TVS Invoice Date',
                'Aging Stock (Days)',
                'Dealer Invoice Status',
                'PDI Status',
              ];
              final rows = filtered
                  .map(
                    (s) => [
                      s.vehicleModel,
                      s.color,
                      s.frameNo,
                      s.engineNo,
                      s.quantity,
                      s.tvsInvoiceDate,
                      s.agingStockDays,
                      s.dealerInvoiceStatus,
                      s.pdiStatus.isEmpty ? 'N/A' : s.pdiStatus,
                    ],
                  )
                  .toList();

              if (value == 'csv') {
                await ExportUtils.exportToCsv(
                  fileName: 'Stock_Export',
                  headers: headers,
                  data: rows,
                );
              } else if (value == 'pdf') {
                await ExportUtils.exportToPdf(
                  fileName: 'Stock_Export',
                  title: 'Stock Availability Report',
                  headers: headers,
                  data: rows,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            ],
          ),
        ],
      ),
      body: stockAsync.when(
        data: (stockItems) {
          final filteredStock = stockItems.where((s) {
            if (selectedDateRange.value != null) {
              final start = selectedDateRange.value!.start;
              final end = selectedDateRange.value!.end;
              DateTime? parsedDate;
              final formats = [
                'dd MMM yyyy',
                'dd-MM-yyyy',
                'MM/dd/yyyy',
                'yyyy-MM-dd',
                'dd/MM/yyyy',
              ];
              for (var format in formats) {
                try {
                  parsedDate = DateFormat(format).parseStrict(s.tvsInvoiceDate);
                  break;
                } catch (_) {}
              }
              parsedDate ??= DateTime.tryParse(s.tvsInvoiceDate);

              if (parsedDate != null) {
                final d = DateTime(
                  parsedDate.year,
                  parsedDate.month,
                  parsedDate.day,
                );
                final st = DateTime(start.year, start.month, start.day);
                final en = DateTime(end.year, end.month, end.day);
                if (d.isBefore(st) || d.isAfter(en)) {
                  return false;
                }
              } else {
                return false;
              }
            }
            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              if (!s.vehicleModel.toLowerCase().contains(q) &&
                  !s.frameNo.toLowerCase().contains(q) &&
                  !s.engineNo.toLowerCase().contains(q) &&
                  !s.color.toLowerCase().contains(q)) {
                return false;
              }
            }
            return true;
          }).toList();

          final totalStock = filteredStock.length;
          final availableStock = filteredStock
              .where((s) => s.status.toLowerCase() == 'available')
              .length;
          final blockedStock = filteredStock
              .where((s) => s.status.toLowerCase() == 'blocked')
              .length;

          // Process model-wise count
          final Map<String, int> modelCounts = {};
          for (var stock in filteredStock) {
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Stock',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => searchQuery.value = '',
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => searchQuery.value = value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      DataColumn(label: Text('Model')),
                      DataColumn(label: Text('Color')),
                      DataColumn(label: Text('Frame No')),
                      DataColumn(label: Text('Engine No')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('TVS Invoice Date')),
                      DataColumn(label: Text('Aging Stock (Days)')),
                      DataColumn(label: Text('Dealer Invoice Status')),
                      DataColumn(label: Text('PDI Status')),
                    ],
                    rows: filteredStock.map((stock) {
                      return DataRow(
                        cells: [
                          DataCell(Text(stock.vehicleModel)),
                          DataCell(Text(stock.color)),
                          DataCell(Text(stock.frameNo)),
                          DataCell(Text(stock.engineNo)),
                          DataCell(Text(stock.quantity)),
                          DataCell(Text(stock.tvsInvoiceDate)),
                          DataCell(Text(stock.agingStockDays)),
                          DataCell(Text(stock.dealerInvoiceStatus)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  stock.pdiStatus,
                                ).withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(stock.pdiStatus),
                                ),
                              ),
                              child: Text(
                                stock.pdiStatus.isEmpty
                                    ? 'N/A'
                                    : stock.pdiStatus,
                                style: TextStyle(
                                  color: _getStatusColor(stock.pdiStatus),
                                ),
                              ),
                            ),
                          ),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
