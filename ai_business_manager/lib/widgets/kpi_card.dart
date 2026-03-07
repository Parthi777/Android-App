import 'package:flutter/material.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30), // Very soft, large radius
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(
                0.15,
              ), // Diffuse shadow tinted to icon color
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ), // More vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space items
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8), // Prevent icon from overlapping
                Container(
                  padding: const EdgeInsets.all(
                    8,
                  ), // Reduced padding to save horizontal space
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.6,
                    ), // Soft white background for icon
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28, // Slightly larger, bolder value text
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
