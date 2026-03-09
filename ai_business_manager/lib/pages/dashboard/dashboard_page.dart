import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/stats_provider.dart';
import '../../providers/data_providers.dart';

import '../../widgets/kpi_card.dart';
import 'charts/enquiry_charts.dart';
import 'charts/sales_charts.dart';
import 'charts/sales_funnel_chart.dart';

import 'charts/stock_charts.dart';
import 'charts/finance_rto_charts.dart';

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    final selectedMonth = ref.watch(selectedDashboardMonthProvider);

    bool isInSelectedMonth(DateTime date) {
      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }

    final allEnquiries = ref.watch(enquiriesProvider).value ?? [];
    final allBookings = ref.watch(bookingsProvider).value ?? [];
    final allSoldItems = ref.watch(soldProvider).value ?? [];
    final stockItems = ref.watch(stockProvider).value ?? [];

    final enquiries = allEnquiries
        .where((e) => isInSelectedMonth(e.date))
        .toList();
    final bookings = allBookings
        .where((b) => isInSelectedMonth(b.bookingDate))
        .toList();
    final soldItems = allSoldItems
        .where((s) => isInSelectedMonth(s.saleDate))
        .toList();

    final now = DateTime.now();
    final todayRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(enquiriesProvider);
          ref.invalidate(bookingsProvider);
          ref.invalidate(soldProvider);
          ref.invalidate(stockProvider);
          // Wait briefly for invalidation to trigger re-fetches
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[900],
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's check your business performance today",
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Today's Highlights
              Text(
                "Today's Highlights",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KPICard(
                      title: "Today's Sales",
                      value: stats.todaySalesCount.toString(),
                      icon: Icons.point_of_sale,
                      gradientColors: const [
                        Color(0xFF5A5599),
                        Color(0xFF332F66),
                      ],
                      onTap: () {
                        context.push(
                          '/sales/sold',
                          extra: {
                            'initialDateRange': todayRange,
                            'drillDownTitle': "Today's Sales",
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KPICard(
                      title: "Today's Bookings",
                      value: stats.todayBookingsCount.toString(),
                      icon: Icons.book_online,
                      gradientColors: const [
                        Color(0xFF289098),
                        Color(0xFF0B5E65),
                      ],
                      onTap: () {
                        context.push(
                          '/sales/bookings',
                          extra: {
                            'initialDateRange': todayRange,
                            'drillDownTitle': "Today's Bookings",
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KPICard(
                      title: "Today's Enquiries",
                      value: stats.todayEnquiriesCount.toString(),
                      icon: Icons.person_search,
                      gradientColors: const [
                        Color(0xFF70C276),
                        Color(0xFF3B8E42),
                      ],
                      onTap: () {
                        context.push(
                          '/sales/enquiry',
                          extra: {
                            'initialDateRange': todayRange,
                            'drillDownTitle': "Today's Enquiries",
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(), // Empty space to keep cards same width
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Overall Summary
              Text(
                "Overall Summary",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KPICard(
                      title: "Overall Active Enquiries",
                      value: stats.activeEnquiriesCount.toString(),
                      icon: Icons.person_search,
                      maxLines: 2,
                      gradientColors: const [
                        Color(0xFF70C276),
                        Color(0xFF3B8E42),
                      ],
                      onTap: () {
                        context.push(
                          '/sales/enquiry',
                          extra: {
                            'preFilterData': allEnquiries
                                .where(
                                  (e) =>
                                      e.status.toLowerCase() != 'closed' &&
                                      e.status.toLowerCase() != 'lost',
                                )
                                .toList(),
                            'drillDownTitle': "Overall Active Enquiries",
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KPICard(
                      title: "Overall Active Bookings",
                      value: stats.totalBookings.toString(),
                      icon: Icons.book_online,
                      maxLines: 2,
                      gradientColors: const [
                        Color(0xFF289098),
                        Color(0xFF0B5E65),
                      ],
                      onTap: () {
                        context.push(
                          '/sales/bookings',
                          extra: {
                            'preFilterData': allBookings,
                            'drillDownTitle': "Overall Active Bookings",
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Performance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final currentMonth = ref.read(
                        selectedDashboardMonthProvider,
                      );
                      final DateTime? picked = await showMonthPicker(
                        context: context,
                        initialDate: currentMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        monthPickerDialogSettings: MonthPickerDialogSettings(
                          headerSettings: const PickerHeaderSettings(
                            headerBackgroundColor: Colors.white,
                            headerCurrentPageTextStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            headerSelectedIntervalTextStyle: TextStyle(
                              color: Color(0xFFFF8B8B), // Soft Coral
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            headerIconsColor: Colors.black,
                          ),
                          dialogSettings: const PickerDialogSettings(
                            dialogRoundedCornersRadius: 24,
                            dialogBackgroundColor: Colors.white,
                          ),
                          dateButtonsSettings: const PickerDateButtonsSettings(
                            selectedMonthBackgroundColor: Color(0xFFFF8B8B),
                            selectedMonthTextColor: Colors.white,
                          ),
                        ),
                      );
                      if (picked != null) {
                        ref
                            .read(selectedDashboardMonthProvider.notifier)
                            .setMonth(picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(
                      DateFormat(
                        'MMM yyyy',
                      ).format(ref.watch(selectedDashboardMonthProvider)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Cards Grid (Monthly)
              Row(
                children: [
                  Expanded(
                    child: KPICard(
                      title: "Total Sales",
                      value: stats.monthlySalesCount.toString(),
                      icon: Icons.point_of_sale,
                      gradientColors: const [
                        Color(0xFF5A5599),
                        Color(0xFF332F66),
                      ],
                      onTap: () => context.push(
                        '/sales/sold',
                        extra: {
                          'preFilterData': soldItems,
                          'drillDownTitle':
                              'Sales — ${DateFormat('MMM yyyy').format(selectedMonth)}',
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KPICard(
                      title: "Total Bookings",
                      value: stats.monthlyBookingsCount.toString(),
                      icon: Icons.book_online,
                      gradientColors: const [
                        Color(0xFF289098),
                        Color(0xFF0B5E65),
                      ],
                      onTap: () => context.push(
                        '/sales/bookings',
                        extra: {
                          'preFilterData': bookings,
                          'drillDownTitle':
                              'Bookings — ${DateFormat('MMM yyyy').format(selectedMonth)}',
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KPICard(
                      title: "Active Enquiries",
                      value: stats.monthlyActiveEnquiriesCount.toString(),
                      icon: Icons.person_search,
                      gradientColors: const [
                        Color(0xFF70C276),
                        Color(0xFF3B8E42),
                      ],
                      onTap: () => context.push(
                        '/sales/enquiry',
                        extra: {
                          'preFilterData': enquiries,
                          'drillDownTitle':
                              'Enquiries — ${DateFormat('MMM yyyy').format(selectedMonth)}',
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KPICard(
                      title: 'Current Stock',
                      value: stats.currentStockCount.toString(),
                      icon: Icons.inventory_2,
                      gradientColors: const [
                        Color(0xFFE87948),
                        Color(0xFFC44D20),
                      ],
                      onTap: () => context.push(
                        '/stock',
                        extra: {'drillDownTitle': 'Current Stock'},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Sales Funnel',
                icon: Icons.filter_alt,
                child: SizedBox(
                  height: 250,
                  child: SalesFunnelChart(
                    enquiries: enquiries,
                    bookings: bookings,
                    soldItems: soldItems,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Enquiry Trend',
                icon: Icons.insights,
                child: SizedBox(
                  height: 250,
                  child: EnquiryTrendChart(enquiries: enquiries),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Bookings Trend',
                icon: Icons.book_online,
                child: BookingsTrendChart(bookings: bookings),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Sales Trend',
                icon: Icons.trending_up,
                child: SalesTrendChart(soldItems: soldItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Model Wise Sales',
                icon: Icons.bar_chart,
                child: ModelWiseSalesChart(soldItems: soldItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Executive Performance',
                icon: Icons.people,
                child: SalesExecPerformanceChart(soldItems: soldItems),
              ),

              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Stock Distribution',
                icon: Icons.inventory_2_outlined,
                child: StockDistributionChart(stockItems: stockItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Finance vs Cash Distribution',
                icon: Icons.account_balance_wallet,
                child: FinanceDistributionChart(soldItems: soldItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Finance Performance',
                icon: Icons.person_pin,
                child: FinancePerformanceChart(soldItems: soldItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Invoice Status',
                icon: Icons.receipt_long,
                child: InvoiceStatusChart(soldItems: soldItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'RTO Status',
                icon: Icons.assignment_turned_in,
                child: RtoStatusChart(soldItems: soldItems),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'RTO Location Distribution',
                icon: Icons.pin_drop,
                child: RtoLocationChart(soldItems: soldItems),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
