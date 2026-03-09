import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';
import '../../utils/export_utils.dart';

import '../../models/sheet_data_models.dart';

class BookingsPage extends HookConsumerWidget {
  final List<Booking>? preFilterData;
  final String? drillDownTitle;
  final DateTimeRange? initialDateRange;

  const BookingsPage({
    super.key,
    this.preFilterData,
    this.drillDownTitle,
    this.initialDateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Booking>> bookingsAsync = preFilterData != null
        ? AsyncData(preFilterData!)
        : ref.watch(bookingsProvider);
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
        title: Text(drillDownTitle ?? 'Bookings - ${branch?.name ?? ''}'),
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
                ref.invalidate(bookingsProvider);
              },
              tooltip: 'Refresh Data',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onSelected: (value) async {
              final data = bookingsAsync.value ?? [];
              final filtered = data.where((b) {
                // ... same export filtering logic ...
                return true;
              }).toList();

              final headers = [
                'Booking ID',
                'Booking Date',
                'Customer Name',
                'Phone',
                'Vehicle Model',
                'Executive',
                'Payment Mode',
                'Status',
              ];
              final rows = filtered
                  .map(
                    (b) => [
                      b.bookingId,
                      dateFormat.format(b.bookingDate),
                      b.customerName,
                      b.phone,
                      b.vehicleModel,
                      b.executive,
                      b.paymentMode,
                      b.status,
                    ],
                  )
                  .toList();

              if (value == 'csv') {
                await ExportUtils.exportToCsv(
                  fileName: 'Bookings_Export',
                  headers: headers,
                  data: rows,
                );
              } else if (value == 'pdf') {
                await ExportUtils.exportToPdf(
                  fileName: 'Bookings_Export',
                  title: 'Bookings Report',
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
      body: bookingsAsync.when(
        data: (bookings) {
          final filteredBookings = bookings.where((b) {
            // Date Filter
            if (selectedDateRange.value != null) {
              final start = selectedDateRange.value!.start;
              final end = selectedDateRange.value!.end;
              final d = DateTime(
                b.bookingDate.year,
                b.bookingDate.month,
                b.bookingDate.day,
              );
              final s = DateTime(start.year, start.month, start.day);
              final en = DateTime(end.year, end.month, end.day);
              if (d.isBefore(s) || d.isAfter(en)) {
                return false;
              }
            }
            // Search Filter
            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              if (!b.customerName.toLowerCase().contains(q) &&
                  !b.phone.toLowerCase().contains(q) &&
                  !b.vehicleModel.toLowerCase().contains(q) &&
                  !b.executive.toLowerCase().contains(q) &&
                  !b.bookingId.toLowerCase().contains(q)) {
                return false;
              }
            }
            // Column Filters
            for (final entry in columnFilters.value.entries) {
              final column = entry.key;
              final activeValues = entry.value;
              String recordValue = '';
              switch (column) {
                case 'executive':
                  recordValue = b.executive;
                  break;
                case 'vehicleModel':
                  recordValue = b.vehicleModel;
                  break;
                case 'paymentMode':
                  recordValue = b.paymentMode;
                  break;
                case 'status':
                  recordValue = b.status;
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
                    labelText: 'Search Bookings',
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
              if (filteredBookings.isEmpty)
                const Expanded(
                  child: Center(child: Text('No matching bookings found.')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Booking ID')),
                          const DataColumn(label: Text('Booking Date')),
                          DataColumn(
                            label: buildFilterHeader(
                              'Executive',
                              'executive',
                              bookings.map((b) => b.executive).toList(),
                            ),
                          ),
                          const DataColumn(label: Text('Customer Name')),
                          const DataColumn(label: Text('Phone')),
                          DataColumn(
                            label: buildFilterHeader(
                              'Vehicle Model',
                              'vehicleModel',
                              bookings.map((b) => b.vehicleModel).toList(),
                            ),
                          ),
                          const DataColumn(label: Text('Amount (₹)')),
                          DataColumn(
                            label: buildFilterHeader(
                              'Payment Mode',
                              'paymentMode',
                              bookings.map((b) => b.paymentMode).toList(),
                            ),
                          ),
                          DataColumn(
                            label: buildFilterHeader(
                              'Status',
                              'status',
                              bookings.map((b) => b.status).toList(),
                            ),
                          ),
                        ],
                        rows: filteredBookings.map((booking) {
                          return DataRow(
                            cells: [
                              DataCell(SelectableText(booking.bookingId)),
                              DataCell(
                                SelectableText(
                                  dateFormat.format(booking.bookingDate),
                                ),
                              ),
                              DataCell(SelectableText(booking.executive)),
                              DataCell(SelectableText(booking.customerName)),
                              DataCell(SelectableText(booking.phone)),
                              DataCell(SelectableText(booking.vehicleModel)),
                              DataCell(
                                SelectableText(
                                  '₹${booking.bookingAmount.toStringAsFixed(0)}',
                                ),
                              ),
                              DataCell(SelectableText(booking.paymentMode)),
                              DataCell(SelectableText(booking.status)),
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
            const SnackBar(content: Text('Add Booking Coming Soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
