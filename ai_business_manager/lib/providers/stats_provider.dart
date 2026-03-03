import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'data_providers.dart';

class DashboardStats {
  final int totalEnquiries;
  final int totalBookings;
  final double totalBookingAmount;
  final List<int> dailyEnquiries; // Last 7 days
  final List<int> dailyBookings; // Last 7 days
  final List<String> last7DaysLabels;

  const DashboardStats({
    this.totalEnquiries = 0,
    this.totalBookings = 0,
    this.totalBookingAmount = 0.0,
    this.dailyEnquiries = const [],
    this.dailyBookings = const [],
    this.last7DaysLabels = const [],
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final enquiries = ref.watch(enquiriesProvider).value ?? [];
  final bookings = ref.watch(bookingsProvider).value ?? [];

  double bookingAmount = 0.0;
  for (final booking in bookings) {
    bookingAmount += booking.bookingAmount;
  }

  // Calculate stats for the last 7 days
  final today = DateTime.now();
  final last7DaysLabels = <String>[];
  final dailyEnquiries = List.filled(7, 0);
  final dailyBookings = List.filled(7, 0);

  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    last7DaysLabels.add('${date.day}/${date.month}');
  }

  for (final enquiry in enquiries) {
    final diff = today.difference(enquiry.date).inDays;
    if (diff >= 0 && diff < 7) {
      dailyEnquiries[6 - diff]++;
    }
  }

  for (final booking in bookings) {
    final diff = today.difference(booking.bookingDate).inDays;
    if (diff >= 0 && diff < 7) {
      dailyBookings[6 - diff]++;
    }
  }

  return DashboardStats(
    totalEnquiries: enquiries.length,
    totalBookings: bookings.length,
    totalBookingAmount: bookingAmount,
    dailyEnquiries: dailyEnquiries,
    dailyBookings: dailyBookings,
    last7DaysLabels: last7DaysLabels,
  );
});
