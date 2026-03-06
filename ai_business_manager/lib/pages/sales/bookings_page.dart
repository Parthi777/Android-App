import 'package:flutter/material.dart';
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

  const BookingsPage({super.key, this.preFilterData, this.drillDownTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Booking>> bookingsAsync = preFilterData != null
        ? AsyncData(preFilterData!)
        : ref.watch(bookingsProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final searchQuery = useState('');
    final selectedDateRange = useState<DateTimeRange?>(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(drillDownTitle ?? 'Bookings - ${branch?.name ?? ''}'),
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
                  if (d.isBefore(s) || d.isAfter(en)) return false;
                }
                if (searchQuery.value.isNotEmpty) {
                  final q = searchQuery.value.toLowerCase();
                  if (!b.customerName.toLowerCase().contains(q) &&
                      !b.phone.toLowerCase().contains(q) &&
                      !b.vehicleModel.toLowerCase().contains(q) &&
                      !b.executive.toLowerCase().contains(q) &&
                      !b.bookingId.toLowerCase().contains(q))
                    return false;
                }
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
                        columns: const [
                          DataColumn(label: Text('Booking ID')),
                          DataColumn(label: Text('Booking Date')),
                          DataColumn(label: Text('Executive')),
                          DataColumn(label: Text('Customer Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Vehicle Model')),
                          DataColumn(label: Text('Amount (₹)')),
                          DataColumn(label: Text('Payment Mode')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: filteredBookings.map((booking) {
                          return DataRow(
                            cells: [
                              DataCell(Text(booking.bookingId)),
                              DataCell(
                                Text(dateFormat.format(booking.bookingDate)),
                              ),
                              DataCell(Text(booking.executive)),
                              DataCell(Text(booking.customerName)),
                              DataCell(Text(booking.phone)),
                              DataCell(Text(booking.vehicleModel)),
                              DataCell(
                                Text(
                                  '₹${booking.bookingAmount.toStringAsFixed(0)}',
                                ),
                              ),
                              DataCell(Text(booking.paymentMode)),
                              DataCell(Text(booking.status)),
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
          // TODO: Implement Add Booking
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Booking Coming Soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
