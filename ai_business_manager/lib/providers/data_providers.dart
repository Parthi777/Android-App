import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/sheet_data_models.dart';
import '../services/google_sheet_service.dart';
import 'branch_provider.dart';

// -- ENQUIRIES --
final enquiriesProvider = FutureProvider<List<Enquiry>>((ref) async {
  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final rawData = await sheetService.getSheetData(
    branch.googleSheetId,
    "'Enquiry'!A1:Z",
  );

  if (rawData == null || rawData.isEmpty) return [];

  // Assuming first row is headers
  return rawData.skip(1).map((row) => Enquiry.fromRow(row)).toList();
});

// -- BOOKINGS --
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final rawData = await sheetService.getSheetData(
    branch.googleSheetId,
    "'Bookings'!A1:Z",
  );

  if (rawData == null || rawData.isEmpty) return [];

  return rawData.skip(1).map((row) => Booking.fromRow(row)).toList();
});

// -- SOLD --
final soldProvider = FutureProvider<List<Sold>>((ref) async {
  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final rawData = await sheetService.getSheetData(
    branch.googleSheetId,
    "'Sold'!A1:Z",
  );

  if (rawData == null || rawData.isEmpty) return [];
  return rawData.skip(1).map((row) => Sold.fromRow(row)).toList();
});

// -- STOCK --
final stockProvider = FutureProvider<List<Stock>>((ref) async {
  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final rawData = await sheetService.getSheetData(
    branch.googleSheetId,
    "'Stock'!A1:Z",
  );

  if (rawData == null || rawData.isEmpty) return [];
  return rawData.skip(1).map((row) => Stock.fromRow(row)).toList();
});
