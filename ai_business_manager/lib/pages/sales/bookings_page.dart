import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';

class BookingsPage extends HookConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings - ${branch?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(bookingsProvider),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Booking ID')),
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Vehicle Model')),
                  DataColumn(label: Text('Amount (₹)')),
                ],
                rows: bookings.map((booking) {
                  return DataRow(
                    cells: [
                      DataCell(Text(dateFormat.format(booking.bookingDate))),
                      DataCell(Text(booking.bookingId)),
                      DataCell(Text(booking.customerName)),
                      DataCell(Text(booking.vehicleModel)),
                      DataCell(
                        Text('₹${booking.bookingAmount.toStringAsFixed(0)}'),
                      ),
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
