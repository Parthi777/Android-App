import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/stats_provider.dart';
import '../../providers/data_providers.dart';
import 'widgets/dashboard_charts.dart';
import '../../widgets/kpi_card.dart';

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
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
              // Title Header
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // KPI Cards Grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: KPICard(
                      title: "Total Sales",
                      value:
                          "${currencyFormat.format(stats.monthlyRevenue)} (${stats.monthlySalesCount})",
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
