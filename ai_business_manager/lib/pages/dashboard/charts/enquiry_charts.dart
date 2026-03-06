import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/sheet_data_models.dart';
import '../../sales/enquiry_page.dart';

class EnquiryTrendChart extends StatelessWidget {
  final List<Enquiry> enquiries;

  const EnquiryTrendChart({super.key, required this.enquiries});

  @override
  Widget build(BuildContext context) {
    if (enquiries.isEmpty) {
      return const Center(child: Text("No Enquiry Data"));
    }

    // Group by Date (ignoring time)
    final Map<DateTime, List<Enquiry>> grouped = {};
    for (var e in enquiries) {
      final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
      grouped.putIfAbsent(dateOnly, () => []).add(e);
    }

    if (grouped.isEmpty) return const SizedBox.shrink();

    // Sort by date ascending
    final sortedKeys = grouped.keys.toList()..sort();

    // To make X axis numeric, we can use the index of the sorted keys.
    final List<FlSpot> spots = [];
    double maxY = 0;
    for (int i = 0; i < sortedKeys.length; i++) {
      final count = grouped[sortedKeys[i]]!.length.toDouble();
      if (count > maxY) maxY = count;
      spots.add(FlSpot(i.toDouble(), count));
    }

    final dateFormat = DateFormat('dd MMM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enquiry Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
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
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index < 0 || index >= sortedKeys.length) {
                        return const SizedBox.shrink();
                      }
                      if (sortedKeys.length > 7 &&
                          index % (sortedKeys.length ~/ 5) != 0 &&
                          index != sortedKeys.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        angle: -0.5,
                        child: Text(
                          dateFormat.format(sortedKeys[index]),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (sortedKeys.length - 1).toDouble(),
              minY: 0,
              maxY: maxY + (maxY * 0.2),
              lineTouchData: LineTouchData(
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      if (touchResponse == null ||
                          touchResponse.lineBarSpots == null) {
                        return;
                      }
                      if (event is FlTapUpEvent) {
                        final spotIndex =
                            touchResponse.lineBarSpots!.first.spotIndex;
                        final selectedDate = sortedKeys[spotIndex];
                        final filteredEnquiries = grouped[selectedDate]!;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EnquiryPage(
                              preFilterData: filteredEnquiries,
                              drillDownTitle:
                                  "Enquiries on ${dateFormat.format(selectedDate)}",
                            ),
                          ),
                        );
                      }
                    },
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  gradient: const LinearGradient(
                    colors: [Colors.cyan, Colors.blueAccent],
                  ),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyan.withOpacity(0.3),
                        Colors.blueAccent.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
