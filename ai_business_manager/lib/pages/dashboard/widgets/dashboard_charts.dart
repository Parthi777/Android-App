import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/stats_provider.dart';
import 'dart:math';

class MonthlyTrendChart extends StatelessWidget {
  final DashboardStats stats;

  const MonthlyTrendChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.monthlySalesTrend.isEmpty || stats.last30DaysLabels.isEmpty) {
      return const Center(child: Text("No Trend Data"));
    }

    final maxS = stats.monthlySalesTrend.reduce(max).toDouble();
    final maxB = stats.monthlyBookingsTrend.reduce(max).toDouble();
    final maxE = stats.monthlyEnquiriesTrend.reduce(max).toDouble();
    final maxY = max(maxS, max(maxB, maxE));

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, 'Sales'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.blue, 'Bookings'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange, 'Enquiries'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index < 0 || index >= stats.last30DaysLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          stats.last30DaysLabels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0)
                        return const SizedBox.shrink(); // Only show integers
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY + (maxY * 0.2), // Add a 20% buffer on top
              lineBarsData: [
                _createLineData(stats.monthlySalesTrend, Colors.green),
                _createLineData(stats.monthlyBookingsTrend, Colors.blue),
                _createLineData(stats.monthlyEnquiriesTrend, Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _createLineData(List<int> data, Color color) {
    return LineChartBarData(
      spots: data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
          .toList(),
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ModelDistributionPieChart extends StatelessWidget {
  final DashboardStats stats;

  const ModelDistributionPieChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.topSellingModels.isEmpty) {
      return const Center(child: Text("No Model Data"));
    }

    // Sort to get top 4, group rest into 'Other'
    final sortedEntries = stats.topSellingModels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(4).toList();
    final otherCount = sortedEntries
        .skip(4)
        .fold(0, (sum, item) => sum + item.value);

    if (otherCount > 0) {
      topEntries.add(MapEntry('Other', otherCount));
    }

    final colors = [
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.lightBlue,
      Colors.grey,
    ];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: topEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: data.value.toDouble(),
                  title: '${data.value}',
                  radius: 30,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[index % colors.length],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
