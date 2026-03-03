import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';
import '../../utils/export_utils.dart';

class SoldPage extends HookConsumerWidget {
  const SoldPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soldAsync = ref.watch(soldProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final searchQuery = useState('');
    final selectedDateRange = useState<DateTimeRange?>(null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sold Vehicles - ${branch?.name ?? ''}'),
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
                  if (d.isBefore(st) || d.isAfter(en)) return false;
                }
                if (searchQuery.value.isNotEmpty) {
                  final q = searchQuery.value.toLowerCase();
                  if (!s.customerName.toLowerCase().contains(q) &&
                      !s.mobileNo.toLowerCase().contains(q) &&
                      !s.vehicleModel.toLowerCase().contains(q) &&
                      !s.executiveName.toLowerCase().contains(q) &&
                      !s.frameNo.toLowerCase().contains(q))
                    return false;
                }
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
                        columns: const [
                          DataColumn(label: Text('Sales Date')),
                          DataColumn(label: Text('Customer Name')),
                          DataColumn(label: Text('Mobile No')),
                          DataColumn(label: Text('Executive Name')),
                          DataColumn(label: Text('Vehicle Model')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Engine No')),
                          DataColumn(label: Text('Frame No')),
                          DataColumn(label: Text('Vehicle Cost (₹)')),
                          DataColumn(label: Text('Ex.Fittings')),
                          DataColumn(label: Text('Discount Operated (₹)')),
                          DataColumn(label: Text('Downpayment (₹)')),
                          DataColumn(label: Text('Cash/HP')),
                          DataColumn(label: Text('Financier Name')),
                          DataColumn(label: Text('Document Charges')),
                          DataColumn(label: Text('Finance DD (₹)')),
                          DataColumn(label: Text('Customer Balance (₹)')),
                          DataColumn(label: Text('Exchange Vehicle')),
                          DataColumn(label: Text('Exchange Value (₹)')),
                          DataColumn(
                            label: Text('Exchange Vehicle Sold Status'),
                          ),
                          DataColumn(label: Text('Exchange Vehicle Mfg')),
                          DataColumn(label: Text('Invoice Status')),
                          DataColumn(label: Text('Invoice Date')),
                          DataColumn(label: Text('RTO Location')),
                          DataColumn(label: Text('RTO')),
                          DataColumn(label: Text('Registration No')),
                        ],
                        rows: filteredSold.map((sold) {
                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(sold.saleDate))),
                              DataCell(Text(sold.customerName)),
                              DataCell(Text(sold.mobileNo)),
                              DataCell(Text(sold.executiveName)),
                              DataCell(Text(sold.vehicleModel)),
                              DataCell(Text(sold.category)),
                              DataCell(Text(sold.engineNo)),
                              DataCell(Text(sold.frameNo)),
                              DataCell(
                                Text('₹${sold.vehicleCost.toStringAsFixed(0)}'),
                              ),
                              DataCell(Text(sold.exFittings)),
                              DataCell(Text(sold.discountOperated)),
                              DataCell(Text(sold.downpayment)),
                              DataCell(Text(sold.cashHp)),
                              DataCell(Text(sold.financierName)),
                              DataCell(Text(sold.documentCharges)),
                              DataCell(Text(sold.financeDd)),
                              DataCell(Text(sold.customerBalance)),
                              DataCell(Text(sold.exchangeVehicle)),
                              DataCell(Text(sold.exchangeValue)),
                              DataCell(Text(sold.exchangeVehicleSoldStatus)),
                              DataCell(Text(sold.exchangeVehicleManufacturing)),
                              DataCell(Text(sold.invoiceStatus)),
                              DataCell(Text(sold.invoiceDate)),
                              DataCell(Text(sold.rtoLocation)),
                              DataCell(Text(sold.rto)),
                              DataCell(Text(sold.registerationNo)),
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
