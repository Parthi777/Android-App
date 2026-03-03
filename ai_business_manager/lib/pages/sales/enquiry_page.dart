import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';

class EnquiryPage extends HookConsumerWidget {
  const EnquiryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enquiriesAsync = ref.watch(enquiriesProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Enquiries - ${branch?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(enquiriesProvider),
          ),
        ],
      ),
      body: enquiriesAsync.when(
        data: (enquiries) {
          if (enquiries.isEmpty) {
            return const Center(child: Text('No enquiries found.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Model Interested')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Handled By')),
                ],
                rows: enquiries.map((enquiry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(dateFormat.format(enquiry.date))),
                      DataCell(Text(enquiry.customerName)),
                      DataCell(Text(enquiry.phone)),
                      DataCell(Text(enquiry.modelInterested)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              enquiry.status,
                            ).withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(enquiry.status),
                            ),
                          ),
                          child: Text(
                            enquiry.status,
                            style: TextStyle(
                              color: _getStatusColor(enquiry.status),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(enquiry.handledBy)),
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
          // TODO: Implement Add Enquiry
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Enquiry Coming Soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'hot':
        return Colors.red;
      case 'warm':
        return Colors.orange;
      case 'cold':
        return Colors.grey;
      case 'converted':
        return Colors.green;
      case 'lost':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
