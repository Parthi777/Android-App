import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/branch.dart';

final googleSheetServiceProvider = Provider<GoogleSheetService>((ref) {
  return GoogleSheetService();
});

class GoogleSheetService {
  static const _scopes = [sheets.SheetsApi.spreadsheetsScope];
  sheets.SheetsApi? _sheetsApi;

  // Initialize with Service Account credentials
  // The service account JSON file should be added to assets or retrieved securely
  Future<void> initialize(String credentialsAssetPath) async {
    try {
      final jsonString = await rootBundle.loadString(credentialsAssetPath);
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      final client = await clientViaServiceAccount(credentials, _scopes);
      _sheetsApi = sheets.SheetsApi(client);
    } catch (e) {
      throw Exception('Failed to initialize Google Sheets API: $e');
    }
  }

  // Fetch all rows from a specific sheet
  Future<List<List<Object?>>?> getSheetData(
    String spreadsheetId,
    String range,
  ) async {
    if (_sheetsApi == null) {
      throw Exception('Google Sheets API is not initialized.');
    }

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        range,
      );
      return response.values;
    } catch (e) {
      throw Exception('Failed to fetch data from Google Sheets: $e');
    }
  }

  // Append a row to a specific sheet
  Future<bool> appendRow(
    String spreadsheetId,
    String range,
    List<Object?> rowData,
  ) async {
    if (_sheetsApi == null) {
      throw Exception('Google Sheets API is not initialized.');
    }

    try {
      final valueRange = sheets.ValueRange(values: [rowData]);
      final response = await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
      return response.updates?.updatedRows != null &&
          response.updates!.updatedRows! > 0;
    } catch (e) {
      throw Exception('Failed to append data to Google Sheets: $e');
    }
  }

  // Update a specific row in a sheet
  Future<bool> updateRow(
    String spreadsheetId,
    String range,
    List<Object?> rowData,
  ) async {
    if (_sheetsApi == null) {
      throw Exception('Google Sheets API is not initialized.');
    }

    try {
      final valueRange = sheets.ValueRange(values: [rowData]);
      final response = await _sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
      return response.updatedRows != null && response.updatedRows! > 0;
    } catch (e) {
      throw Exception('Failed to update data in Google Sheets: $e');
    }
  }

  // Helper method to convert branch Configuration into Data
  Future<List<Map<String, dynamic>>> fetchBranchData(
    Branch branch,
    String sheetGid,
  ) async {
    // In Google Sheets API, to fetch by GID you usually need the Sheet Name.
    // This helper will act as an interface to combine those.
    // For now, it's a placeholder struct returning empty list until Sheet Names are strictly mapped.
    return [];
  }
}
