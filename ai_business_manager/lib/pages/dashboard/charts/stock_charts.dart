import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../models/sheet_data_models.dart';

// ─── Pastel colors matching the 3D reference ────────────────────────
const _k3dColors = [
  Color(0xFFF08080), // Coral/Pink
  Color(0xFF90DA8A), // Soft Green
  Color(0xFFFFD87A), // Soft Yellow
  Color(0xFFA89CE0), // Lavender/Purple
  Color(0xFF77C4DE), // Sky Blue
];

// Darker shades for 3D bottom face
const _k3dShadowColors = [
  Color(0xFFC04040),
  Color(0xFF4AA044),
  Color(0xFFCCA020),
  Color(0xFF6050B0),
  Color(0xFF3090B0),
];

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
    if (widget.stockItems.isEmpty) {
      return const Center(child: Text("No Stock Data"));
    }

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

    return _ThreeDDonutChart(
      entries: topEntries.map((e) => MapEntry(e.key, e.value.length)).toList(),
      colors: _k3dColors,
      shadowColors: _k3dShadowColors,
      touchedIndex: touchedIndex,
      onTouched: (i) => setState(() => touchedIndex = i),
      onTap: (i) {
        final modelName = topEntries[i].key;
        final filteredStock = topEntries[i].value;
        context.push(
          '/stock',
          extra: {
            'preFilterData': filteredStock,
            'drillDownTitle': "Stock: $modelName",
          },
        );
      },
    );
  }
}

// ─── Reusable 3D Donut Chart Widget ──────────────────────────────────
class _ThreeDDonutChart extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final List<Color> shadowColors;
  final int touchedIndex;
  final ValueChanged<int> onTouched;
  final ValueChanged<int> onTap;

  const _ThreeDDonutChart({
    required this.entries,
    required this.colors,
    required this.shadowColors,
    required this.touchedIndex,
    required this.onTouched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 3D Donut ──────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom 3D shadow layer — shifted down to simulate depth
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: PieChart(
                  PieChartData(
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 6,
                    centerSpaceRadius: 42,
                    startDegreeOffset: -90,
                    sections: entries.asMap().entries.map((e) {
                      return PieChartSectionData(
                        color: shadowColors[e.key % shadowColors.length],
                        value: e.value.value.toDouble(),
                        title: '',
                        radius: 62,
                        borderSide: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Top face layer — main colors, slightly smaller offset
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, res) {
                      if (res == null || res.touchedSection == null) {
                        onTouched(-1);
                        return;
                      }
                      final idx = res.touchedSection!.touchedSectionIndex;
                      onTouched(idx);
                      if (event is FlTapUpEvent &&
                          idx >= 0 &&
                          idx < entries.length) {
                        onTap(idx);
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 6,
                  centerSpaceRadius: 42,
                  startDegreeOffset: -90,
                  sections: entries.asMap().entries.map((e) {
                    final isTouched = e.key == touchedIndex;
                    return PieChartSectionData(
                      color: colors[e.key % colors.length],
                      value: e.value.value.toDouble(),
                      title: '',
                      radius: isTouched ? 68 : 62,
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 0,
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Center label
              if (touchedIndex >= 0 && touchedIndex < entries.length)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entries[touchedIndex].value}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors[touchedIndex % colors.length],
                      ),
                    ),
                    Text(
                      entries[touchedIndex].key,
                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Legend below the chart ────────────────────────────────
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.asMap().entries.map((e) {
            final pct = total > 0
                ? (e.value.value / total * 100).toStringAsFixed(1)
                : '0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[e.key % colors.length],
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: colors[e.key % colors.length].withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.value.key} ($pct%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
