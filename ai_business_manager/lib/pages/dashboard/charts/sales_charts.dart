import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/sheet_data_models.dart';

// ─── Shared horizontal bar widget with 3D look ───────────────────────
class _HorizontalBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _HorizontalBar({
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
            // Label above the bar
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
            // Bar with 3D layered effect
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth * fraction;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Shadow layer (3D depth)
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
                    // Main gradient bar
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
                            color: gradientColors.last.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      // Count label inside bar
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
                    // If bar is too small, show count after bar
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

// ─── Model-wise Sales Chart ───────────────────────────────────────────
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

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topEntries = entries.take(6).toList();
    final maxCount = topEntries.isEmpty ? 1 : topEntries.first.value.length;

    final gradients = [
      [const Color(0xFF5A5599), const Color(0xFF332F66)],
      [const Color(0xFF289098), const Color(0xFF0B5E65)],
      [const Color(0xFF70C276), const Color(0xFF3B8E42)],
      [const Color(0xFFE87948), const Color(0xFFC44D20)],
      [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
      [const Color(0xFF8E24AA), const Color(0xFF5C0E72)],
    ];

    return Column(
      children: topEntries.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;
        return _HorizontalBar(
          label: entry.key,
          count: entry.value.length,
          maxCount: maxCount,
          gradientColors: gradients[index % gradients.length],
          onTap: () {
            context.push(
              '/sales/sold',
              extra: {
                'preFilterData': entry.value,
                'drillDownTitle': "Sales: ${entry.key}",
              },
            );
          },
        );
      }).toList(),
    );
  }
}

// ─── Sales Executive Performance Chart ───────────────────────────────
class SalesExecPerformanceChart extends StatelessWidget {
  final List<Sold> soldItems;

  const SalesExecPerformanceChart({super.key, required this.soldItems});

  @override
  Widget build(BuildContext context) {
    if (soldItems.isEmpty) {
      return const Center(child: Text("No Executive Data"));
    }

    final Map<String, List<Sold>> grouped = {};
    for (var s in soldItems) {
      if (s.executiveName.trim().isEmpty) continue;
      grouped.putIfAbsent(s.executiveName, () => []).add(s);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topEntries = entries.take(6).toList();
    final maxCount = topEntries.isEmpty ? 1 : topEntries.first.value.length;

    final gradients = [
      [const Color(0xFF8E24AA), const Color(0xFF5C0E72)],
      [const Color(0xFFE87948), const Color(0xFFC44D20)],
      [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
      [const Color(0xFF289098), const Color(0xFF0B5E65)],
      [const Color(0xFF70C276), const Color(0xFF3B8E42)],
      [const Color(0xFF5A5599), const Color(0xFF332F66)],
    ];

    return Column(
      children: topEntries.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;
        final firstName = entry.key.split(' ').first;
        return _HorizontalBar(
          label: firstName,
          count: entry.value.length,
          maxCount: maxCount,
          gradientColors: gradients[index % gradients.length],
          onTap: () {
            context.push(
              '/sales/sold',
              extra: {
                'preFilterData': entry.value,
                'drillDownTitle': "Sales by ${entry.key}",
              },
            );
          },
        );
      }).toList(),
    );
  }
}
