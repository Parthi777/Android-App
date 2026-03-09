import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../models/sheet_data_models.dart';

// ─── Shared Line Trend Builder ────────────────────────────────────────
Widget _buildLineTrend<T>({
  required BuildContext context,
  required List<T> items,
  required DateTime Function(T) getDate,
  required String emptyMessage,
  required List<Color> lineColors,
  required void Function(List<T>, DateTime, String) onTap,
}) {
  if (items.isEmpty) return Center(child: Text(emptyMessage));

  final Map<DateTime, List<T>> grouped = {};
  for (var e in items) {
    final d = getDate(e);
    final dateOnly = DateTime(d.year, d.month, d.day);
    grouped.putIfAbsent(dateOnly, () => []).add(e);
  }
  if (grouped.isEmpty) return const SizedBox.shrink();

  final sortedKeys = grouped.keys.toList()..sort();
  final List<FlSpot> spots = [];
  double maxY = 0;
  for (int i = 0; i < sortedKeys.length; i++) {
    final count = grouped[sortedKeys[i]]!.length.toDouble();
    if (count > maxY) maxY = count;
    spots.add(FlSpot(i.toDouble(), count));
  }
  final dateFormat = DateFormat('dd/MM');

  return SizedBox(
    height: 250,
    child: LineChart(
      LineChartData(
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
              reservedSize: 36,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 11,
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
              reservedSize: 48,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                final total = sortedKeys.length;
                if (idx < 0 || idx >= total) return const SizedBox.shrink();

                // Adaptive step: show fewer labels as data grows
                final int step = total <= 7
                    ? 1
                    : total <= 15
                    ? 2
                    : total <= 22
                    ? 3
                    : 5; // ~weekly for 23-31 days

                // Always show first and last; thin the rest adaptively
                final bool show =
                    idx == 0 || idx == total - 1 || idx % step == 0;
                if (!show) return const SizedBox.shrink();

                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  angle: total > 10 ? -0.72 : -0.4,
                  child: Text(
                    dateFormat.format(sortedKeys[idx]),
                    style: TextStyle(
                      fontSize: total > 20 ? 9 : 10,
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
        maxY: maxY + (maxY * 0.25).clamp(1, double.infinity),
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? res) {
            if (res == null || res.lineBarSpots == null) return;
            if (event is FlTapUpEvent) {
              final spotIndex = res.lineBarSpots!.first.spotIndex;
              final selectedDate = sortedKeys[spotIndex];
              final label = dateFormat.format(selectedDate);
              onTap(grouped[selectedDate]!, selectedDate, label);
            }
          },
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, indicators) {
            return indicators.map((i) {
              return TouchedSpotIndicatorData(
                FlLine(color: lineColors.first, strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: lineColors.first,
                      ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toInt().toString(),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            gradient: LinearGradient(colors: lineColors),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: lineColors.first,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColors.first.withValues(alpha: 0.4),
                  lineColors.last.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Enquiry Trend Chart ──────────────────────────────────────────────
class EnquiryTrendChart extends StatelessWidget {
  final List<Enquiry> enquiries;

  const EnquiryTrendChart({super.key, required this.enquiries});

  @override
  Widget build(BuildContext context) {
    return _buildLineTrend<Enquiry>(
      context: context,
      items: enquiries,
      getDate: (e) => e.date,
      emptyMessage: 'No Enquiry Data',
      lineColors: const [Color(0xFF00BCD4), Color(0xFF1E88E5)],
      onTap: (list, date, label) => context.push(
        '/sales/enquiry',
        extra: {'preFilterData': list, 'drillDownTitle': 'Enquiries on $label'},
      ),
    );
  }
}

// ─── Bookings Trend Chart ─────────────────────────────────────────────
class BookingsTrendChart extends StatelessWidget {
  final List<Booking> bookings;

  const BookingsTrendChart({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return _buildLineTrend<Booking>(
      context: context,
      items: bookings,
      getDate: (b) => b.bookingDate,
      emptyMessage: 'No Bookings Data',
      lineColors: const [Color(0xFF7B52AB), Color(0xFFE040FB)],
      onTap: (list, date, label) => context.push(
        '/sales/bookings',
        extra: {'preFilterData': list, 'drillDownTitle': 'Bookings on $label'},
      ),
    );
  }
}

// ─── Sales Trend Chart ────────────────────────────────────────────────
class SalesTrendChart extends StatelessWidget {
  final List<Sold> soldItems;

  const SalesTrendChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    return _buildLineTrend<Sold>(
      context: context,
      items: soldItems,
      getDate: (s) => s.saleDate,
      emptyMessage: 'No Sales Data',
      lineColors: const [Color(0xFF43A047), Color(0xFF00E676)],
      onTap: (list, date, label) => context.push(
        '/sales/sold',
        extra: {'preFilterData': list, 'drillDownTitle': 'Sales on $label'},
      ),
    );
  }
}
