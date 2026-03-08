import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sheet_data_models.dart';
import '../../sales/sold_page.dart';

class ModelWiseSalesChart extends StatelessWidget {
  final List<Sold> soldItems;

  const ModelWiseSalesChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    if (soldItems.isEmpty) return const Center(child: Text("No Sales Data"));

    final Map<String, List<Sold>> grouped = {};
    for (var s in soldItems) {
      grouped.putIfAbsent(s.vehicleModel, () => []).add(s);
    }

    // Sort by volume descending
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    // Top 5 models for the chart to keep it clean, rest as 'Other' (optional, but let's show top 6)
    final topEntries = entries.take(6).toList();

    double maxY = 0;
    for (var entry in topEntries) {
      if (entry.value.length > maxY) maxY = entry.value.length.toDouble();
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: false,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.08), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= topEntries.length)
                  return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  angle: -0.5,
                  child: Text(
                    topEntries[index].key,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxY + (maxY * 0.2),
        barGroups: topEntries.asMap().entries.map((e) {
          final index = e.key;
          final data = e.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.length.toDouble(),
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.lightBlueAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 22,
                borderRadius: BorderRadius.circular(100),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (barTouchResponse == null || barTouchResponse.spot == null) {
              return;
            }
            if (event is FlTapUpEvent) {
              final index = barTouchResponse.spot!.touchedBarGroupIndex;
              final modelName = topEntries[index].key;
              final filteredData = topEntries[index].value;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SoldPage(
                    preFilterData: filteredData,
                    drillDownTitle: "Sales: $modelName",
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class SalesExecPerformanceChart extends StatelessWidget {
  final List<Sold> soldItems;

  const SalesExecPerformanceChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    if (soldItems.isEmpty)
      return const Center(child: Text("No Executive Data"));

    final Map<String, List<Sold>> grouped = {};
    for (var s in soldItems) {
      if (s.executiveName.trim().isEmpty) continue;
      grouped.putIfAbsent(s.executiveName, () => []).add(s);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topEntries = entries.take(6).toList();

    double maxY = 0;
    for (var entry in topEntries) {
      if (entry.value.length > maxY) maxY = entry.value.length.toDouble();
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: false,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.08), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= topEntries.length)
                  return const SizedBox.shrink();
                final names = topEntries[index].key.split(' ');
                final shortName = names.isNotEmpty
                    ? names.first
                    : topEntries[index].key;
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  angle: -0.5,
                  child: Text(
                    shortName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxY + (maxY * 0.2),
        barGroups: topEntries.asMap().entries.map((e) {
          final index = e.key;
          final data = e.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.length.toDouble(),
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.pinkAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 22,
                borderRadius: BorderRadius.circular(100),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (barTouchResponse == null || barTouchResponse.spot == null) {
              return;
            }
            if (event is FlTapUpEvent) {
              final index = barTouchResponse.spot!.touchedBarGroupIndex;
              final execName = topEntries[index].key;
              final filteredData = topEntries[index].value;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SoldPage(
                    preFilterData: filteredData,
                    drillDownTitle: "Sales by $execName",
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
