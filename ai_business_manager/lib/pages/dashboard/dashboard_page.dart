import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/stats_provider.dart';
import '../../providers/data_providers.dart';
import '../sales/sold_page.dart';
import '../sales/bookings_page.dart';
import '../sales/enquiry_page.dart';
import 'widgets/dashboard_charts.dart';
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

    final enquiries = ref.watch(enquiriesProvider).value ?? [];
    final bookings = ref.watch(bookingsProvider).value ?? [];
    final soldItems = ref.watch(soldProvider).value ?? [];
    final stockItems = ref.watch(stockProvider).value ?? [];

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
              // Title Header
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

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
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SoldPage()),
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
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingsPage(),
                          ),
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
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EnquiryPage(),
                          ),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Overview',
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
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: currentMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        helpText: 'Select a Date in the Target Month',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KPICard(
                      title: "Total Bookings",
                      value: stats.monthlyBookingsCount.toString(),
                      icon: Icons.book_online,
                      color: Colors.blueAccent,
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
                      value: stats.activeEnquiriesCount.toString(),
                      icon: Icons.person_search,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KPICard(
                      title: 'Current Stock',
                      value: stats.currentStockCount.toString(),
                      icon: Icons.inventory_2,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sales Trend Chart
              _buildSectionCard(
                title: 'Monthly Trends (Last 30 Days)',
                icon: Icons.trending_up,
                child: SizedBox(
                  height: 250,
                  child: MonthlyTrendChart(stats: stats),
                ),
              ),
              const SizedBox(height: 24),

              // Top Selling Models Donut
              _buildSectionCard(
                title: 'Top Selling Models',
                icon: Icons.pie_chart,
                child: SizedBox(
                  height: 220,
                  child: ModelDistributionPieChart(stats: stats),
                ),
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
                title: 'Model Wise Sales',
                icon: Icons.bar_chart,
                child: SizedBox(
                  height: 250,
                  child: ModelWiseSalesChart(soldItems: soldItems),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Executive Performance',
                icon: Icons.people,
                child: SizedBox(
                  height: 250,
                  child: SalesExecPerformanceChart(soldItems: soldItems),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Stock Distribution',
                icon: Icons.inventory_2_outlined,
                child: SizedBox(
                  height: 250,
                  child: StockDistributionChart(stockItems: stockItems),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Finance vs Cash Distribution',
                icon: Icons.account_balance_wallet,
                child: SizedBox(
                  height: 250,
                  child: FinanceDistributionChart(soldItems: soldItems),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'Invoice Status',
                icon: Icons.receipt_long,
                child: SizedBox(
                  height: 250,
                  child: InvoiceStatusChart(soldItems: soldItems),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'RTO Status',
                icon: Icons.assignment_turned_in,
                child: SizedBox(
                  height: 250,
                  child: RtoStatusChart(soldItems: soldItems),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                title: 'RTO Location Distribution',
                icon: Icons.pin_drop,
                child: SizedBox(
                  height: 250,
                  child: RtoLocationChart(soldItems: soldItems),
                ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
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
