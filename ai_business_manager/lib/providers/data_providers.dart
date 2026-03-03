import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/sheet_data_models.dart';
import '../services/google_sheet_service.dart';
import 'branch_provider.dart';

// -- ENQUIRIES --
final enquiriesProvider = FutureProvider.autoDispose<List<Enquiry>>((
  ref,
) async {
  // Real-time syncing
  final timer = Timer(const Duration(seconds: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final sheetName = await sheetService.getSheetNameFromGid(
    branch.googleSheetId,
    branch.enquirySheetGid,
  );
  if (sheetName == null)
    throw Exception(
      "Could not find Enquiry Sheet Tab for GID: \${branch.enquirySheetGid}",
    );

  return sheetService.fetchModelRows(
    branch.googleSheetId,
    sheetName,
    (row) => Enquiry.fromRow(row),
  );
});

// -- BOOKINGS --
final bookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final timer = Timer(const Duration(seconds: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final sheetName = await sheetService.getSheetNameFromGid(
    branch.googleSheetId,
    branch.bookingSheetGid,
  );
  if (sheetName == null)
    throw Exception(
      "Could not find Bookings Sheet Tab for GID: \${branch.bookingSheetGid}",
    );

  return sheetService.fetchModelRows(
    branch.googleSheetId,
    sheetName,
    (row) => Booking.fromRow(row),
  );
});

// -- SOLD --
final soldProvider = FutureProvider.autoDispose<List<Sold>>((ref) async {
  final timer = Timer(const Duration(seconds: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final sheetName = await sheetService.getSheetNameFromGid(
    branch.googleSheetId,
    branch.soldSheetGid,
  );
  if (sheetName == null)
    throw Exception(
      "Could not find Sold Sheet Tab for GID: \${branch.soldSheetGid}",
    );

  return sheetService.fetchModelRows(
    branch.googleSheetId,
    sheetName,
    (row) => Sold.fromRow(row),
  );
});

// -- STOCK --
final stockProvider = FutureProvider.autoDispose<List<Stock>>((ref) async {
  final timer = Timer(const Duration(seconds: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final branch = ref.watch(branchProvider);
  if (branch == null) return [];

  final sheetService = ref.watch(googleSheetServiceProvider);
  final sheetName = await sheetService.getSheetNameFromGid(
    branch.googleSheetId,
    branch.stockSheetGid,
  );
  if (sheetName == null)
    throw Exception(
      "Could not find Stock Sheet Tab for GID: \${branch.stockSheetGid}",
    );

  return sheetService.fetchModelRows(
    branch.googleSheetId,
    sheetName,
    (row) => Stock.fromRow(row),
  );
});
