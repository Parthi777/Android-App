import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'data_providers.dart';

// New provider to track the selected month for the dashboard
class SelectedDashboardMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

final selectedDashboardMonthProvider =
    NotifierProvider<SelectedDashboardMonthNotifier, DateTime>(
      SelectedDashboardMonthNotifier.new,
    );

class DashboardStats {
  final int totalEnquiries;
  final int totalBookings;
  final double totalBookingAmount;
  final int todaySalesCount;
  final double todayRevenue;
  final int todayBookingsCount;
  final int todayEnquiriesCount;
  final int monthlySalesCount;
  final double monthlyRevenue;
  final int monthlyBookingsCount;
  final int monthlyActiveEnquiriesCount;
  final int activeEnquiriesCount;
  final int currentStockCount;
  final List<int> monthlySalesTrend;
  final List<int> monthlyBookingsTrend;
  final List<int> monthlyEnquiriesTrend;
  final List<String> last30DaysLabels;
  final Map<String, int> topSellingModels;

  DashboardStats({
    this.totalEnquiries = 0,
    this.totalBookings = 0,
    this.totalBookingAmount = 0.0,
    this.todaySalesCount = 0,
    this.todayRevenue = 0.0,
    this.todayBookingsCount = 0,
    this.todayEnquiriesCount = 0,
    this.monthlySalesCount = 0,
    this.monthlyRevenue = 0.0,
    this.monthlyBookingsCount = 0,
    this.monthlyActiveEnquiriesCount = 0,
    this.activeEnquiriesCount = 0,
    this.currentStockCount = 0,
    this.monthlySalesTrend = const [],
    this.monthlyBookingsTrend = const [],
    this.monthlyEnquiriesTrend = const [],
    this.last30DaysLabels = const [],
    this.topSellingModels = const {},
  }) {
    // Constructor Body
  }
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final enquiriesAsync = ref.watch(enquiriesProvider);
  final bookingsAsync = ref.watch(bookingsProvider);
  final soldAsync = ref.watch(soldProvider);
  final stockAsync = ref.watch(stockProvider);
  final selectedMonth = ref.watch(selectedDashboardMonthProvider);

  final enquiries = enquiriesAsync.value ?? [];
  final bookings = bookingsAsync.value ?? [];
  final soldList = soldAsync.value ?? [];
  final stockList = stockAsync.value ?? [];

  final today = DateTime.now();

  int tSalesCount = 0;
  double tRevenue = 0.0;
  int tBookingsCount = 0;
  int tEnquiriesCount = 0;

  int mSalesCount = 0;
  double mRevenue = 0.0;
  int mBookingsCount = 0;
  int mActiveEnquiriesCount = 0;
  int aEnquiriesCount = 0;
  int tStock = 0;

  Map<String, int> sellingModels = {};

  final daysInMonth = DateTime(
    selectedMonth.year,
    selectedMonth.month + 1,
    0,
  ).day;

  final monthLabels = <String>[];
  final mSalesTrend = List.filled(daysInMonth, 0);
  final mBookingsTrend = List.filled(daysInMonth, 0);
  final mEnquiriesTrend = List.filled(daysInMonth, 0);

  // Pre-fill labels for the selected month days
  for (int i = 1; i <= daysInMonth; i++) {
    if (i % 5 == 0 || i == 1) {
      monthLabels.add('$i/${selectedMonth.month}');
    } else {
      monthLabels.add('');
    }
  }

  // Helper to check if date is today
  bool isToday(DateTime date) {
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // Helper to check if date is in selected month
  bool isInSelectedMonth(DateTime date) {
    return date.year == selectedMonth.year && date.month == selectedMonth.month;
  }

  // Aggregate Enquiries
  for (final enquiry in enquiries) {
    if (enquiry.status.toLowerCase() != 'closed' &&
        enquiry.status.toLowerCase() != 'lost') {
      aEnquiriesCount++;
    }

    if (isToday(enquiry.date)) {
      tEnquiriesCount++;
    }

    if (isInSelectedMonth(enquiry.date)) {
      if (enquiry.status.toLowerCase() != 'closed' &&
          enquiry.status.toLowerCase() != 'lost') {
        mActiveEnquiriesCount++;
      }
      final idx = enquiry.date.day - 1;
      if (idx >= 0 && idx < daysInMonth) {
        mEnquiriesTrend[idx]++;
      }
    }
  }

  // Aggregate Bookings
  for (final booking in bookings) {
    if (isToday(booking.bookingDate)) {
      tBookingsCount++;
    }

    if (isInSelectedMonth(booking.bookingDate)) {
      mBookingsCount++;
      final idx = booking.bookingDate.day - 1;
      if (idx >= 0 && idx < daysInMonth) {
        mBookingsTrend[idx]++;
      }
    }
  }

  // Aggregate Sold
  for (final sold in soldList) {
    if (isToday(sold.saleDate)) {
      tSalesCount++;
      tRevenue += sold.vehicleCost;
    }

    if (isInSelectedMonth(sold.saleDate)) {
      mSalesCount++;
      mRevenue += sold.vehicleCost;

      final idx = sold.saleDate.day - 1;
      if (idx >= 0 && idx < daysInMonth) {
        mSalesTrend[idx]++;
      }
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
    todaySalesCount: tSalesCount,
    todayRevenue: tRevenue,
    todayBookingsCount: tBookingsCount,
    todayEnquiriesCount: tEnquiriesCount,
    monthlySalesCount: mSalesCount,
    monthlyRevenue: mRevenue,
    monthlyBookingsCount: mBookingsCount,
    monthlyActiveEnquiriesCount: mActiveEnquiriesCount,
    activeEnquiriesCount: aEnquiriesCount,
    currentStockCount: tStock,
    monthlySalesTrend: mSalesTrend,
    monthlyBookingsTrend: mBookingsTrend,
    monthlyEnquiriesTrend: mEnquiriesTrend,
    last30DaysLabels: monthLabels,
    topSellingModels: sellingModels,
  );
});
