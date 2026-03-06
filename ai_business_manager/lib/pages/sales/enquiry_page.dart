import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../providers/data_providers.dart';
import '../../providers/branch_provider.dart';
import '../../utils/export_utils.dart';

import '../../models/sheet_data_models.dart';

class EnquiryPage extends HookConsumerWidget {
  final List<Enquiry>? preFilterData;
  final String? drillDownTitle;

  const EnquiryPage({super.key, this.preFilterData, this.drillDownTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Enquiry>> enquiriesAsync = preFilterData != null
        ? AsyncData(preFilterData!)
        : ref.watch(enquiriesProvider);
    final branch = ref.watch(branchProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final searchQuery = useState('');
    final selectedDateRange = useState<DateTimeRange?>(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(drillDownTitle ?? 'Enquiries - ${branch?.name ?? ''}'),
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
                ref.invalidate(enquiriesProvider);
              },
              tooltip: 'Refresh Data',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onSelected: (value) async {
              final data = enquiriesAsync.value ?? [];
              final filtered = data.where((e) {
                if (selectedDateRange.value != null) {
                  final start = selectedDateRange.value!.start;
                  final end = selectedDateRange.value!.end;
                  final d = DateTime(e.date.year, e.date.month, e.date.day);
                  final s = DateTime(start.year, start.month, start.day);
                  final en = DateTime(end.year, end.month, end.day);
                  if (d.isBefore(s) || d.isAfter(en)) return false;
                }
                if (searchQuery.value.isNotEmpty) {
                  final q = searchQuery.value.toLowerCase();
                  if (!e.customerName.toLowerCase().contains(q) &&
                      !e.phone.toLowerCase().contains(q) &&
                      !e.modelInterested.toLowerCase().contains(q) &&
                      !e.executive.toLowerCase().contains(q))
                    return false;
                }
                return true;
              }).toList();

              final headers = [
                'Date',
                'Customer Name',
                'Phone',
                'Model Interested',
                'Executive',
                'Source',
                'Status',
              ];
              final rows = filtered
                  .map(
                    (e) => [
                      dateFormat.format(e.date),
                      e.customerName,
                      e.phone,
                      e.modelInterested,
                      e.executive,
                      e.source,
                      e.status,
                    ],
                  )
                  .toList();

              if (value == 'csv') {
                await ExportUtils.exportToCsv(
                  fileName: 'Enquiries_Export',
                  headers: headers,
                  data: rows,
                );
              } else if (value == 'pdf') {
                await ExportUtils.exportToPdf(
                  fileName: 'Enquiries_Export',
                  title: 'Enquiries Report',
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
      body: enquiriesAsync.when(
        data: (enquiries) {
          final filteredEnquiries = enquiries.where((e) {
            if (selectedDateRange.value != null) {
              final start = selectedDateRange.value!.start;
              final end = selectedDateRange.value!.end;
              final d = DateTime(e.date.year, e.date.month, e.date.day);
              final s = DateTime(start.year, start.month, start.day);
              final en = DateTime(end.year, end.month, end.day);
              if (d.isBefore(s) || d.isAfter(en)) {
                return false;
              }
            }
            if (searchQuery.value.isNotEmpty) {
              final q = searchQuery.value.toLowerCase();
              if (!e.customerName.toLowerCase().contains(q) &&
                  !e.phone.toLowerCase().contains(q) &&
                  !e.modelInterested.toLowerCase().contains(q) &&
                  !e.executive.toLowerCase().contains(q) &&
                  !e.id.toLowerCase().contains(q)) {
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
                    labelText: 'Search Enquiries',
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
              if (filteredEnquiries.isEmpty)
                const Expanded(
                  child: Center(child: Text('No matching enquiries found.')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Enquiry ID')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Executive')),
                          DataColumn(label: Text('Customer Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Model Interested')),
                          DataColumn(label: Text('Source')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: filteredEnquiries.map((enquiry) {
                          return DataRow(
                            cells: [
                              DataCell(Text(enquiry.id)),
                              DataCell(Text(dateFormat.format(enquiry.date))),
                              DataCell(Text(enquiry.executive)),
                              DataCell(Text(enquiry.customerName)),
                              DataCell(Text(enquiry.phone)),
                              DataCell(Text(enquiry.modelInterested)),
                              DataCell(Text(enquiry.source)),
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
