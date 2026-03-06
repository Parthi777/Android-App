import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sheet_data_models.dart';
import '../../stock/stock_page.dart';

class StockDistributionChart extends StatefulWidget {
  final List<Stock> stockItems;

  const StockDistributionChart({super.key, required this.stockItems});

  @override
  State<StockDistributionChart> createState() => _StockDistributionChartState();
}

class _StockDistributionChartState extends State<StockDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.stockItems.isEmpty)
      return const Center(child: Text("No Stock Data"));

    final Map<String, List<Stock>> grouped = {};
    for (var s in widget.stockItems) {
      final qty = int.tryParse(s.quantity) ?? 0;
      if (qty <= 0) continue;
      grouped.putIfAbsent(s.vehicleModel, () => []).add(s);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topEntries = entries.take(4).toList();
    final otherCount = entries
        .skip(4)
        .fold<int>(0, (sum, e) => sum + e.value.length);
    if (otherCount > 0) {
      topEntries.add(
        MapEntry('Others', entries.skip(4).expand((e) => e.value).toList()),
      );
    }

    final colors = [
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.lightBlue,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
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
                          touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;

                          if (event is FlTapUpEvent &&
                              touchedIndex >= 0 &&
                              touchedIndex < topEntries.length) {
                            final modelName = topEntries[touchedIndex].key;
                            final filteredStock =
                                topEntries[touchedIndex].value;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockPage(
                                  preFilterData: filteredStock,
                                  drillDownTitle: "Stock: $modelName",
                                ),
                              ),
                            );
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: topEntries.asMap().entries.map((entry) {
                      final isTouched = entry.key == touchedIndex;
                      final radius = isTouched ? 45.0 : 35.0;
                      final data = entry.value;
                      return PieChartSectionData(
                        color: colors[entry.key % colors.length],
                        value: data.value.length.toDouble(),
                        title: '${data.value.length}',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 16 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                  children: topEntries.asMap().entries.map((entry) {
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
          ),
        ),
      ],
    );
  }
}
