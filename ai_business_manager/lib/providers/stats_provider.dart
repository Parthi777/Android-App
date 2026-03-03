import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'data_providers.dart';

class DashboardStats {
  // Original properties needed by ai_chat_modal.dart
  final int totalEnquiries;
  final int totalBookings;
  final double totalBookingAmount;

  // Monthly (Last 30 Days) / Total properties
  final int monthlySalesCount;
  final double monthlyRevenue;
  final int monthlyBookingsCount;
  final int activeEnquiriesCount;
  final int currentStockCount;

  // Trend lines (Last 30 Days)
  final List<int> monthlySalesTrend;
  final List<int> monthlyBookingsTrend;
  final List<int> monthlyEnquiriesTrend;
  final List<String> last30DaysLabels;

  // Breakdown
  final Map<String, int> topSellingModels;

  const DashboardStats({
    this.totalEnquiries = 0,
    this.totalBookings = 0,
    this.totalBookingAmount = 0.0,
    this.monthlySalesCount = 0,
    this.monthlyRevenue = 0.0,
    this.monthlyBookingsCount = 0,
    this.activeEnquiriesCount = 0,
    this.currentStockCount = 0,
    this.monthlySalesTrend = const [],
    this.monthlyBookingsTrend = const [],
    this.monthlyEnquiriesTrend = const [],
    this.last30DaysLabels = const [],
    this.topSellingModels = const {},
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final enquiries = ref.watch(enquiriesProvider).value ?? [];
  final bookings = ref.watch(bookingsProvider).value ?? [];
  final soldList = ref.watch(soldProvider).value ?? [];
  final stockList = ref.watch(stockProvider).value ?? [];

  final today = DateTime.now();

  int mSalesCount = 0;
  double mRevenue = 0.0;
  int mBookingsCount = 0;
  int aEnquiriesCount = 0;
  int tStock = 0;

  Map<String, int> sellingModels = {};

  final last30DaysLabels = <String>[];
  final mSalesTrend = List.filled(30, 0);
  final mBookingsTrend = List.filled(30, 0);
  final mEnquiriesTrend = List.filled(30, 0);

  // Pre-fill labels for the last 30 days
  for (int i = 29; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    // Only show label every 5 days for space
    if (i % 5 == 0 || i == 0) {
      last30DaysLabels.add(DateFormat('MM/dd').format(date));
    } else {
      last30DaysLabels.add('');
    }
  }

  // Aggregate Enquiries
  for (final enquiry in enquiries) {
    if (enquiry.status.toLowerCase() != 'closed' &&
        enquiry.status.toLowerCase() != 'lost') {
      aEnquiriesCount++;
    }

    final diff = today.difference(enquiry.date).inDays;
    if (diff >= 0 && diff < 30) {
      final index = 29 - diff;
      mEnquiriesTrend[index]++;
    }
  }

  // Aggregate Bookings
  for (final booking in bookings) {
    final diff = today.difference(booking.bookingDate).inDays;
    if (diff >= 0 && diff < 30) {
      mBookingsCount++;
      final index = 29 - diff;
      mBookingsTrend[index]++;
    }
  }

  // Aggregate Sold
  for (final sold in soldList) {
    final diff = today.difference(sold.saleDate).inDays;
    if (diff >= 0 && diff < 30) {
      mSalesCount++;
      mRevenue += sold.vehicleCost;

      final index = 29 - diff;
      mSalesTrend[index]++;
    }

    // Top Selling Models Donut Chart
    if (sold.vehicleModel.isNotEmpty) {
      sellingModels[sold.vehicleModel] =
          (sellingModels[sold.vehicleModel] ?? 0) + 1;
    }
  }

  // Aggregate Stock
  for (final stock in stockList) {
    tStock += int.tryParse(stock.quantity) ?? 0;
  }

  // Calculate original properties
  double bookingAmount = 0.0;
  for (final booking in bookings) {
    bookingAmount += booking.bookingAmount;
  }

  return DashboardStats(
    totalEnquiries: enquiries.length,
    totalBookings: bookings.length,
    totalBookingAmount: bookingAmount,
    monthlySalesCount: mSalesCount,
    monthlyRevenue: mRevenue,
    monthlyBookingsCount: mBookingsCount,
    activeEnquiriesCount: aEnquiriesCount,
    currentStockCount: tStock,
    monthlySalesTrend: mSalesTrend,
    monthlyBookingsTrend: mBookingsTrend,
    monthlyEnquiriesTrend: mEnquiriesTrend,
    last30DaysLabels: last30DaysLabels,
    topSellingModels: sellingModels,
  );
});
