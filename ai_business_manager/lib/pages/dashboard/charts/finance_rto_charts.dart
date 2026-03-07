import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sheet_data_models.dart';
import '../../sales/sold_page.dart';

class FinanceDistributionChart extends StatefulWidget {
  final List<Sold> soldItems;

  const FinanceDistributionChart({super.key, required this.soldItems});

  @override
  State<FinanceDistributionChart> createState() =>
      _FinanceDistributionChartState();
}

class _FinanceDistributionChartState extends State<FinanceDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.soldItems.isEmpty)
      return const Center(child: Text("No Finance Data"));

    final Map<String, List<Sold>> grouped = {'Cash': [], 'Finance': []};
    for (var s in widget.soldItems) {
      final isCash =
          s.financierName.trim().isEmpty ||
          s.financierName.trim().toLowerCase() == 'cash';
      if (isCash) {
        grouped['Cash']!.add(s);
      } else {
        grouped['Finance']!.add(s);
      }
    }

    // Only show groups with data
    final entries = grouped.entries.where((e) => e.value.isNotEmpty).toList();

    return _buildPieChart(
      title: 'Finance vs Cash',
      entries: entries,
      colors: [Colors.indigoAccent, Colors.purpleAccent],
      context: context,
    );
  }

  Widget _buildPieChart({
    required String title,
    required List<MapEntry<String, List<Sold>>> entries,
    required List<Color> colors,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;

                    if (event is FlTapUpEvent &&
                        touchedIndex >= 0 &&
                        touchedIndex < entries.length) {
                      final groupName = entries[touchedIndex].key;
                      final filteredSales = entries[touchedIndex].value;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoldPage(
                            preFilterData: filteredSales,
                            drillDownTitle: "Sales: $title - $groupName",
                          ),
                        ),
                      );
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 45,
              sections: entries.asMap().entries.map((entry) {
                final isTouched = entry.key == touchedIndex;
                final radius = isTouched ? 25.0 : 20.0;
                final data = entry.value;
                return PieChartSectionData(
                  color: colors[entry.key % colors.length],
                  value: data.value.length.toDouble(),
                  title: '', // Remove text from thin ring
                  radius: radius,
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((entry) {
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
                        color: colors[entry.key % colors.length],
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

class InvoiceStatusChart extends StatefulWidget {
  final List<Sold> soldItems;

  const InvoiceStatusChart({super.key, required this.soldItems});

  @override
  State<InvoiceStatusChart> createState() => _InvoiceStatusChartState();
}

class _InvoiceStatusChartState extends State<InvoiceStatusChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.soldItems.isEmpty)
      return const Center(child: Text("No Invoice Data"));

    final Map<String, List<Sold>> grouped = {};
    for (var s in widget.soldItems) {
      final status = s.invoiceStatus.trim().isEmpty
          ? 'Pending'
          : s.invoiceStatus.trim();
      grouped.putIfAbsent(status, () => []).add(s);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;

                    if (event is FlTapUpEvent &&
                        touchedIndex >= 0 &&
                        touchedIndex < entries.length) {
                      final groupName = entries[touchedIndex].key;
                      final filteredSales = entries[touchedIndex].value;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoldPage(
                            preFilterData: filteredSales,
                            drillDownTitle: "Invoice: $groupName",
                          ),
                        ),
                      );
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 45,
              sections: entries.asMap().entries.map((entry) {
                final isTouched = entry.key == touchedIndex;
                final radius = isTouched ? 25.0 : 20.0;
                final data = entry.value;
                final isDone =
                    data.key.toLowerCase().contains("done") ||
                    data.key.toLowerCase().contains("complet") ||
                    data.key.toLowerCase() == "yes";
                return PieChartSectionData(
                  color: isDone ? Colors.green[400] : Colors.orange[400],
                  value: data.value.length.toDouble(),
                  title: '', // Remove text
                  radius: radius,
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((entry) {
              final data = entry.value;
              final isDone =
                  data.key.toLowerCase().contains("done") ||
                  data.key.toLowerCase().contains("complet") ||
                  data.key.toLowerCase() == "yes";
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? Colors.green[400] : Colors.orange[400],
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

class RtoStatusChart extends StatefulWidget {
  final List<Sold> soldItems;

  const RtoStatusChart({super.key, required this.soldItems});

  @override
  State<RtoStatusChart> createState() => _RtoStatusChartState();
}

class _RtoStatusChartState extends State<RtoStatusChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.soldItems.isEmpty)
      return const Center(child: Text("No RTO Data"));

    final Map<String, List<Sold>> grouped = {};
    for (var s in widget.soldItems) {
      final status = s.rto.trim().isEmpty ? 'Pending' : s.rto.trim();
      grouped.putIfAbsent(status, () => []).add(s);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;

                    if (event is FlTapUpEvent &&
                        touchedIndex >= 0 &&
                        touchedIndex < entries.length) {
                      final groupName = entries[touchedIndex].key;
                      final filteredSales = entries[touchedIndex].value;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoldPage(
                            preFilterData: filteredSales,
                            drillDownTitle: "RTO: $groupName",
                          ),
                        ),
                      );
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 45,
              sections: entries.asMap().entries.map((entry) {
                final isTouched = entry.key == touchedIndex;
                final radius = isTouched ? 25.0 : 20.0;
                final data = entry.value;
                final isDone =
                    data.key.toLowerCase().contains("done") ||
                    data.key.toLowerCase().contains("complet") ||
                    data.key.toLowerCase() == "yes";
                return PieChartSectionData(
                  color: isDone ? Colors.teal[400] : Colors.amber[500],
                  value: data.value.length.toDouble(),
                  title: '', // Remove text
                  radius: radius,
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((entry) {
              final data = entry.value;
              final isDone =
                  data.key.toLowerCase().contains("done") ||
                  data.key.toLowerCase().contains("complet") ||
                  data.key.toLowerCase() == "yes";
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? Colors.teal[400] : Colors.amber[500],
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

class RtoLocationChart extends StatelessWidget {
  final List<Sold> soldItems;

  const RtoLocationChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    if (soldItems.isEmpty)
      return const Center(child: Text("No RTO Location Data"));

    final Map<String, List<Sold>> grouped = {};
    for (var s in soldItems) {
      if (s.rtoLocation.trim().isEmpty) continue;
      grouped.putIfAbsent(s.rtoLocation, () => []).add(s);
    }

    if (grouped.isEmpty)
      return const Center(child: Text("No RTO Location Data"));

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topEntries = entries.take(5).toList();

    double maxY = 0;
    for (var entry in topEntries) {
      if (entry.value.length > maxY) maxY = entry.value.length.toDouble();
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
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
                  colors: [Colors.pink, Colors.pinkAccent],
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
              final locationName = topEntries[index].key;
              final filteredData = topEntries[index].value;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SoldPage(
                    preFilterData: filteredData,
                    drillDownTitle: "RTO Region: $locationName",
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
