import 'package:flutter/material.dart';
import '../../../models/sheet_data_models.dart';
import '../../sales/enquiry_page.dart';
import '../../sales/bookings_page.dart';
import '../../sales/sold_page.dart';

class SalesFunnelChart extends StatelessWidget {
  final List<Enquiry> enquiries;
  final List<Booking> bookings;
  final List<Sold> soldItems;

  const SalesFunnelChart({
    super.key,
    required this.enquiries,
    required this.bookings,
    required this.soldItems,
  });

  @override
  Widget build(BuildContext context) {
    if (enquiries.isEmpty && bookings.isEmpty && soldItems.isEmpty) {
      return const Center(child: Text("No Funnel Data"));
    }

    final maxVal = [
      enquiries.length,
      bookings.length,
      soldItems.length,
    ].reduce((curr, next) => curr > next ? curr : next);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFunnelStage(
              context,
              label: "Enquiries",
              count: enquiries.length,
              max: maxVal,
              maxWidth: width,
              color: Colors.cyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnquiryPage(
                    preFilterData: enquiries,
                    drillDownTitle: "Funnel: Enquiries",
                  ),
                ),
              ),
            ),
            _buildFunnelStage(
              context,
              label: "Bookings",
              count: bookings.length,
              max: maxVal,
              maxWidth: width,
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingsPage(
                    preFilterData: bookings,
                    drillDownTitle: "Funnel: Bookings",
                  ),
                ),
              ),
            ),
            _buildFunnelStage(
              context,
              label: "Sold",
              count: soldItems.length,
              max: maxVal,
              maxWidth: width,
              color: Colors.indigoAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SoldPage(
                    preFilterData: soldItems,
                    drillDownTitle: "Funnel: Sold",
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFunnelStage(
    BuildContext context, {
    required String label,
    required int count,
    required int max,
    required double maxWidth,
    required Color color,
    required VoidCallback onTap,
  }) {
    // minimum width 40% of max width, otherwise scale based on count relative to max
    final pct = max == 0 ? 0.0 : count / max;
    final stageWidth = (maxWidth * 0.4) + (maxWidth * 0.6 * pct);

    return GestureDetector(
      onTap: onTap,
      child: HoverAnimator(
        child: Container(
          width: stageWidth,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple hover animation wrapper for the funnel stages
class HoverAnimator extends StatefulWidget {
  final Widget child;
  const HoverAnimator({super.key, required this.child});

  @override
  State<HoverAnimator> createState() => _HoverAnimatorState();
}

class _HoverAnimatorState extends State<HoverAnimator> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
