import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sheet_data_models.dart';

// ─── Pastel 3D color palettes ────────────────────────────────────────
const _kFinanceColors = [Color(0xFF77C4DE), Color(0xFFFFD87A)];
const _kFinanceShadow = [Color(0xFF3090B0), Color(0xFFCCA020)];

const _kInvoiceColors = [Color(0xFF90DA8A), Color(0xFFF08080)];
const _kInvoiceShadow = [Color(0xFF4AA044), Color(0xFFC04040)];

const _kRtoStatusColors = [Color(0xFF77C4DE), Color(0xFFFFD87A)];
const _kRtoStatusShadow = [Color(0xFF3090B0), Color(0xFFCCA020)];

// ─── Shared 3D Donut Widget ──────────────────────────────────────────
class _ThreeDDonut extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final List<Color> shadowColors;
  final int touchedIndex;
  final void Function(int) onTouched;
  final void Function(int)? onTap;

  const _ThreeDDonut({
    required this.entries,
    required this.colors,
    required this.shadowColors,
    required this.touchedIndex,
    required this.onTouched,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Donut with 3D depth ────────────────────────────────
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow (lower/darker) layer
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PieChart(
                  PieChartData(
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 6,
                    centerSpaceRadius: 38,
                    startDegreeOffset: -90,
                    sections: entries.asMap().entries.map((e) {
                      return PieChartSectionData(
                        color: shadowColors[e.key % shadowColors.length],
                        value: e.value.value.toDouble(),
                        title: '',
                        radius: 58,
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Top color layer
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
                          idx < entries.length &&
                          onTap != null) {
                        onTap!(idx);
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 6,
                  centerSpaceRadius: 38,
                  startDegreeOffset: -90,
                  sections: entries.asMap().entries.map((e) {
                    final isTouched = e.key == touchedIndex;
                    return PieChartSectionData(
                      color: colors[e.key % colors.length],
                      value: e.value.value.toDouble(),
                      title: '',
                      radius: isTouched ? 64 : 58,
                    );
                  }).toList(),
                ),
              ),
              // Center stat
              if (touchedIndex >= 0 && touchedIndex < entries.length)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entries[touchedIndex].value}',
                      style: TextStyle(
                        fontSize: 20,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Legend below the chart ────────────────────────────
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.asMap().entries.map((e) {
            final pct = total > 0
                ? (e.value.value / total * 100).toStringAsFixed(1)
                : '0';
            final color = colors[e.key % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${e.value.key}  $pct%  (${e.value.value})',
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

// ─── Finance Distribution Chart ──────────────────────────────────────
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
    if (widget.soldItems.isEmpty) {
      return const Center(child: Text("No Finance Data"));
    }

    final Map<String, List<Sold>> grouped = {'Cash': [], 'Finance': []};
    for (var s in widget.soldItems) {
      final isCash =
          s.financierName.trim().isEmpty ||
          s.financierName.trim().toLowerCase() == 'cash';
      (isCash ? grouped['Cash'] : grouped['Finance'])!.add(s);
    }

    final entries = grouped.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => MapEntry(e.key, e.value.length))
        .toList();

    return _ThreeDDonut(
      entries: entries,
      colors: _kFinanceColors,
      shadowColors: _kFinanceShadow,
      touchedIndex: touchedIndex,
      onTouched: (i) => setState(() => touchedIndex = i),
      onTap: (i) {
        final groupName = entries[i].key;
        final filteredSales = widget.soldItems.where((s) {
          final isCash =
              s.financierName.trim().isEmpty ||
              s.financierName.trim().toLowerCase() == 'cash';
          return groupName == 'Cash' ? isCash : !isCash;
        }).toList();
        context.push(
          '/sales/sold',
          extra: {
            'preFilterData': filteredSales,
            'drillDownTitle': "Finance: $groupName",
          },
        );
      },
    );
  }
}

// ─── Finance Executive Performance Chart ──────────────────────────────
class FinanceExecPerformanceChart extends StatelessWidget {
  final List<Sold> soldItems;

  const FinanceExecPerformanceChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    // Filter to only Finance deals
    final financeDeals = soldItems.where((s) {
      final isCash =
          s.financierName.trim().isEmpty ||
          s.financierName.trim().toLowerCase() == 'cash';
      return !isCash;
    }).toList();

    if (financeDeals.isEmpty) {
      return const Center(child: Text("No Finance Executive Data"));
    }

    final Map<String, List<Sold>> grouped = {};
    for (var s in financeDeals) {
      if (s.executiveName.trim().isEmpty) continue;
      grouped.putIfAbsent(s.executiveName, () => []).add(s);
    }

    if (grouped.isEmpty) {
      return const Center(child: Text("No Finance Executive Data"));
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topEntries = entries.take(6).toList();
    final maxCount = topEntries.isEmpty ? 1 : topEntries.first.value.length;

    // Use a distinct premium palette
    final gradients = [
      [const Color(0xFF5A5599), const Color(0xFF332F66)],
      [const Color(0xFFE87948), const Color(0xFFC44D20)],
      [const Color(0xFF289098), const Color(0xFF0B5E65)],
      [const Color(0xFF8E24AA), const Color(0xFF5C0E72)],
      [const Color(0xFF70C276), const Color(0xFF3B8E42)],
      [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
    ];

    return Column(
      children: topEntries.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;
        final firstName = entry.key.split(' ').first;

        return _HBar(
          label: firstName,
          count: entry.value.length,
          maxCount: maxCount,
          gradientColors: gradients[index % gradients.length],
          onTap: () {
            context.push(
              '/sales/sold',
              extra: {
                'preFilterData': entry.value,
                'drillDownTitle': "Finance Sales: ${entry.key}",
              },
            );
          },
        );
      }).toList(),
    );
  }
}

// ─── Invoice Status Chart ─────────────────────────────────────────────
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
    if (widget.soldItems.isEmpty) {
      return const Center(child: Text("No Invoice Data"));
    }

    final Map<String, List<Sold>> grouped = {};
    for (var s in widget.soldItems) {
      final status = s.invoiceStatus.trim().isEmpty
          ? 'Pending'
          : s.invoiceStatus.trim();
      grouped.putIfAbsent(status, () => []).add(s);
    }

    final rawEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final entries = rawEntries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList();

    bool isDone(String key) =>
        key.toLowerCase().contains("done") ||
        key.toLowerCase().contains("complet") ||
        key.toLowerCase() == "yes";

    final colors = entries.map((e) {
      return isDone(e.key) ? _kInvoiceColors[0] : _kInvoiceColors[1];
    }).toList();
    final shadows = entries.map((e) {
      return isDone(e.key) ? _kInvoiceShadow[0] : _kInvoiceShadow[1];
    }).toList();

    return _ThreeDDonut(
      entries: entries,
      colors: colors,
      shadowColors: shadows,
      touchedIndex: touchedIndex,
      onTouched: (i) => setState(() => touchedIndex = i),
      onTap: (i) {
        final groupName = rawEntries[i].key;
        context.push(
          '/sales/sold',
          extra: {
            'preFilterData': rawEntries[i].value,
            'drillDownTitle': "Invoice: $groupName",
          },
        );
      },
    );
  }
}

// ─── RTO Status Chart ─────────────────────────────────────────────────
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
    if (widget.soldItems.isEmpty) {
      return const Center(child: Text("No RTO Data"));
    }

    final Map<String, List<Sold>> grouped = {};
    for (var s in widget.soldItems) {
      final status = s.rto.trim().isEmpty ? 'Pending' : s.rto.trim();
      grouped.putIfAbsent(status, () => []).add(s);
    }

    final rawEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final entries = rawEntries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList();

    bool isDone(String key) =>
        key.toLowerCase().contains("done") ||
        key.toLowerCase().contains("complet") ||
        key.toLowerCase() == "yes";

    final colors = entries.map((e) {
      return isDone(e.key) ? _kRtoStatusColors[0] : _kRtoStatusColors[1];
    }).toList();
    final shadows = entries.map((e) {
      return isDone(e.key) ? _kRtoStatusShadow[0] : _kRtoStatusShadow[1];
    }).toList();

    return _ThreeDDonut(
      entries: entries,
      colors: colors,
      shadowColors: shadows,
      touchedIndex: touchedIndex,
      onTouched: (i) => setState(() => touchedIndex = i),
      onTap: (i) {
        final groupName = rawEntries[i].key;
        context.push(
          '/sales/sold',
          extra: {
            'preFilterData': rawEntries[i].value,
            'drillDownTitle': "RTO: $groupName",
          },
        );
      },
    );
  }
}

// ─── Horizontal Bar Utilities ─────────────────────────────────────────
class _HBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _HBar({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth * fraction;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      child: Container(
                        width: barWidth.clamp(0.0, constraints.maxWidth),
                        height: 28,
                        decoration: BoxDecoration(
                          color: gradientColors.last.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Container(
                      width: barWidth.clamp(0.0, constraints.maxWidth),
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.last.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 10),
                      child: barWidth > 32
                          ? Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    if (barWidth < 32)
                      Positioned(
                        left: barWidth + 6,
                        top: 5,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RtoLocationChart extends StatelessWidget {
  final List<Sold> soldItems;

  const RtoLocationChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    if (soldItems.isEmpty) {
      return const Center(child: Text("No RTO Location Data"));
    }

    final Map<String, List<Sold>> grouped = {};
    for (var s in soldItems) {
      if (s.rtoLocation.trim().isEmpty) continue;
      grouped.putIfAbsent(s.rtoLocation, () => []).add(s);
    }

    if (grouped.isEmpty) {
      return const Center(child: Text("No RTO Location Data"));
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topEntries = entries.take(5).toList();
    final maxCount = topEntries.isEmpty ? 1 : topEntries.first.value.length;

    final gradients = [
      [const Color(0xFFE87948), const Color(0xFFC44D20)],
      [const Color(0xFF5A5599), const Color(0xFF332F66)],
      [const Color(0xFF289098), const Color(0xFF0B5E65)],
      [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
      [const Color(0xFF70C276), const Color(0xFF3B8E42)],
    ];

    return Column(
      children: topEntries.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;
        return _HBar(
          label: entry.key,
          count: entry.value.length,
          maxCount: maxCount,
          gradientColors: gradients[index % gradients.length],
          onTap: () {
            context.push(
              '/sales/sold',
              extra: {
                'preFilterData': entry.value,
                'drillDownTitle': "RTO Region: ${entry.key}",
              },
            );
          },
        );
      }).toList(),
    );
  }
}

// ─── Finance Performance Chart ──────────────────────────────
class FinancePerformanceChart extends StatelessWidget {
  final List<Sold> soldItems;

  const FinancePerformanceChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    // Filter to only Finance deals
    final financeDeals = soldItems.where((s) {
      final isCash =
          s.financierName.trim().isEmpty ||
          s.financierName.trim().toLowerCase() == 'cash';
      return !isCash;
    }).toList();

    if (financeDeals.isEmpty) {
      return const Center(child: Text("No Finance Data"));
    }

    final Map<String, List<Sold>> grouped = {};
    for (var s in financeDeals) {
      if (s.financierName.trim().isEmpty) continue;
      grouped.putIfAbsent(s.financierName, () => []).add(s);
    }

    if (grouped.isEmpty) {
      return const Center(child: Text("No Finance Data"));
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topEntries = entries.take(6).toList();
    final maxCount = topEntries.isEmpty ? 1 : topEntries.first.value.length;

    // Use a distinct premium palette
    final gradients = [
      [const Color(0xFF5A5599), const Color(0xFF332F66)],
      [const Color(0xFFE87948), const Color(0xFFC44D20)],
      [const Color(0xFF289098), const Color(0xFF0B5E65)],
      [const Color(0xFF8E24AA), const Color(0xFF5C0E72)],
      [const Color(0xFF70C276), const Color(0xFF3B8E42)],
      [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
    ];

    return Column(
      children: topEntries.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;

        return _HBar(
          label: entry.key,
          count: entry.value.length,
          maxCount: maxCount,
          gradientColors: gradients[index % gradients.length],
          onTap: () {
            context.push(
              '/sales/sold',
              extra: {
                'preFilterData': entry.value,
                'drillDownTitle': "Financier: ${entry.key}",
              },
            );
          },
        );
      }).toList(),
    );
  }
}
