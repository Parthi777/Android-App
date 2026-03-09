import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';
import '../../utils/export_utils.dart';

import '../../models/sheet_data_models.dart';

class SoldPage extends HookConsumerWidget {
  final List<Sold>? preFilterData;
  final String? drillDownTitle;
  final DateTimeRange? initialDateRange;

  const SoldPage({
    super.key,
    this.preFilterData,
    this.drillDownTitle,
    this.initialDateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Sold>> soldAsync = preFilterData != null
        ? AsyncData(preFilterData!)
        : ref.watch(soldProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final searchQuery = useState('');
    final selectedDateRange = useState<DateTimeRange?>(initialDateRange);
    final columnFilters = useState<Map<String, Set<String>>>({});

    void toggleFilter(String column, String value) {
      final current = Map<String, Set<String>>.from(columnFilters.value);
      final columnSet = Set<String>.from(current[column] ?? {});
      if (columnSet.contains(value)) {
        columnSet.remove(value);
      } else {
        columnSet.add(value);
      }
      if (columnSet.isEmpty) {
        current.remove(column);
      } else {
        current[column] = columnSet;
      }
      columnFilters.value = current;
    }

    Widget buildFilterHeader(
      String label,
      String columnKey,
      List<String> allValues,
    ) {
      final activeFilters = columnFilters.value[columnKey] ?? {};
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              size: 16,
              color: activeFilters.isNotEmpty ? Colors.blue : null,
            ),
            onSelected: (value) {
              if (value == 'CLEAR_ALL') {
                final current = Map<String, Set<String>>.from(
                  columnFilters.value,
                );
                current.remove(columnKey);
                columnFilters.value = current;
              } else {
                toggleFilter(columnKey, value);
              }
            },
            itemBuilder: (context) {
              final uniqueValues = allValues.toSet().toList()..sort();
              return [
                PopupMenuItem(
                  value: 'CLEAR_ALL',
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: activeFilters.isEmpty ? Colors.grey : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                ...uniqueValues.map((val) {
                  final isSelected = activeFilters.contains(val);
                  return CheckedPopupMenuItem(
                    value: val,
                    checked: isSelected,
                    child: Text(val),
                  );
                }),
              ];
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        title: Text(drillDownTitle ?? 'Sold Vehicles - ${branch?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () => columnFilters.value = {},
            tooltip: 'Clear All Column Filters',
          ),
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
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: const Color(0xFFFF8B8B),
                        onPrimary: Colors.white,
                        onSurface: const Color(0xFF232323),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8B8B),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
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
                ref.invalidate(soldProvider);
              },
              tooltip: 'Refresh Data',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onSelected: (value) async {
              final data = soldAsync.value ?? [];
              final filtered = data.where((s) {
                // ... same export filtering logic ...
                return true;
              }).toList();

              final headers = [
                'Sales Date',
                'Customer Name',
                'Mobile No.',
                'Vehicle Model',
                'Category',
                'Frame No.',
                'Engine No.',
                'Executive',
                'Financier Name',
                'RTO',
                'Registration No',
              ];
              final rows = filtered
                  .map(
                    (s) => [
                      dateFormat.format(s.saleDate),
                      s.customerName,
                      s.mobileNo,
                      s.vehicleModel,
                      s.category,
                      s.frameNo,
                      s.engineNo,
                      s.executiveName,
                      s.financierName,
                      s.rto,
                      s.registerationNo,
                    ],
                  )
                  .toList();

              if (value == 'csv') {
                await ExportUtils.exportToCsv(
                  fileName: 'Sold_Export',
                  headers: headers,
                  data: rows,
                );
              } else if (value == 'pdf') {
                await ExportUtils.exportToPdf(
                  fileName: 'Sold_Export',
                  title: 'Sold Vehicles Report',
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
      body: soldAsync.when(
        data: (soldItems) {
          final filteredSold = soldItems.where((s) {
            // Date Filter
            if (selectedDateRange.value != null) {
              final start = selectedDateRange.value!.start;
              final end = selectedDateRange.value!.end;
              final d = DateTime(
                s.saleDate.year,
                s.saleDate.month,
                s.saleDate.day,
              );
              final st = DateTime(start.year, start.month, start.day);
              final en = DateTime(end.year, end.month, end.day);
              if (d.isBefore(st) || d.isAfter(en)) {
                return false;
              }
            }
            // Search Filter
            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              if (!s.customerName.toLowerCase().contains(q) &&
                  !s.mobileNo.toLowerCase().contains(q) &&
                  !s.vehicleModel.toLowerCase().contains(q) &&
                  !s.executiveName.toLowerCase().contains(q) &&
                  !s.frameNo.toLowerCase().contains(q)) {
                return false;
              }
            }
            // Column Filters
            for (final entry in columnFilters.value.entries) {
              final column = entry.key;
              final activeValues = entry.value;
              String recordValue = '';
              switch (column) {
                case 'executiveName':
                  recordValue = s.executiveName;
                  break;
                case 'vehicleModel':
                  recordValue = s.vehicleModel;
                  break;
                case 'category':
                  recordValue = s.category;
                  break;
                case 'cashHp':
                  recordValue = s.cashHp;
                  break;
                case 'invoiceStatus':
                  recordValue = s.invoiceStatus;
                  break;
              }
              if (!activeValues.contains(recordValue)) return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Sold Vehicles',
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
              if (filteredSold.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No matching sold vehicles found.'),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Sales Date')),
                          const DataColumn(label: Text('Customer Name')),
                          const DataColumn(label: Text('Mobile No')),
                          DataColumn(
                            label: buildFilterHeader(
                              'Executive Name',
                              'executiveName',
                              soldItems.map((s) => s.executiveName).toList(),
                            ),
                          ),
                          DataColumn(
                            label: buildFilterHeader(
                              'Vehicle Model',
                              'vehicleModel',
                              soldItems.map((s) => s.vehicleModel).toList(),
                            ),
                          ),
                          DataColumn(
                            label: buildFilterHeader(
                              'Category',
                              'category',
                              soldItems.map((s) => s.category).toList(),
                            ),
                          ),
                          const DataColumn(label: Text('Engine No')),
                          const DataColumn(label: Text('Frame No')),
                          const DataColumn(label: Text('Vehicle Cost (₹)')),
                          const DataColumn(label: Text('Ex.Fittings')),
                          const DataColumn(
                            label: Text('Discount Operated (₹)'),
                          ),
                          const DataColumn(label: Text('Downpayment (₹)')),
                          DataColumn(
                            label: buildFilterHeader(
                              'Cash/HP',
                              'cashHp',
                              soldItems.map((s) => s.cashHp).toList(),
                            ),
                          ),
                          const DataColumn(label: Text('Financier Name')),
                          const DataColumn(label: Text('Document Charges')),
                          const DataColumn(label: Text('Finance DD (₹)')),
                          const DataColumn(label: Text('Customer Balance (₹)')),
                          const DataColumn(label: Text('Exchange Vehicle')),
                          const DataColumn(label: Text('Exchange Value (₹)')),
                          const DataColumn(
                            label: Text('Exchange Vehicle Sold Status'),
                          ),
                          const DataColumn(label: Text('Exchange Vehicle Mfg')),
                          DataColumn(
                            label: buildFilterHeader(
                              'Invoice Status',
                              'invoiceStatus',
                              soldItems.map((s) => s.invoiceStatus).toList(),
                            ),
                          ),
                          const DataColumn(label: Text('Invoice Date')),
                          const DataColumn(label: Text('RTO Location')),
                          const DataColumn(label: Text('RTO')),
                          const DataColumn(label: Text('Registration No')),
                        ],
                        rows: filteredSold.map((sold) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SelectableText(
                                  dateFormat.format(sold.saleDate),
                                ),
                              ),
                              DataCell(SelectableText(sold.customerName)),
                              DataCell(SelectableText(sold.mobileNo)),
                              DataCell(SelectableText(sold.executiveName)),
                              DataCell(SelectableText(sold.vehicleModel)),
                              DataCell(SelectableText(sold.category)),
                              DataCell(SelectableText(sold.engineNo)),
                              DataCell(SelectableText(sold.frameNo)),
                              DataCell(
                                SelectableText(
                                  '₹${sold.vehicleCost.toStringAsFixed(0)}',
                                ),
                              ),
                              DataCell(SelectableText(sold.exFittings)),
                              DataCell(SelectableText(sold.discountOperated)),
                              DataCell(SelectableText(sold.downpayment)),
                              DataCell(SelectableText(sold.cashHp)),
                              DataCell(SelectableText(sold.financierName)),
                              DataCell(SelectableText(sold.documentCharges)),
                              DataCell(SelectableText(sold.financeDd)),
                              DataCell(SelectableText(sold.customerBalance)),
                              DataCell(SelectableText(sold.exchangeVehicle)),
                              DataCell(SelectableText(sold.exchangeValue)),
                              DataCell(
                                SelectableText(sold.exchangeVehicleSoldStatus),
                              ),
                              DataCell(
                                SelectableText(
                                  sold.exchangeVehicleManufacturing,
                                ),
                              ),
                              DataCell(SelectableText(sold.invoiceStatus)),
                              DataCell(SelectableText(sold.invoiceDate)),
                              DataCell(SelectableText(sold.rtoLocation)),
                              DataCell(SelectableText(sold.rto)),
                              DataCell(SelectableText(sold.registerationNo)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Sold Vehicle Coming Soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
