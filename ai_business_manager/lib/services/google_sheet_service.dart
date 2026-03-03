import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/sheet_data_models.dart';

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

  // Generic method to append a mapped model
  Future<bool> appendModelRow(
    String spreadsheetId,
    String sheetName,
    SheetDataMapper model,
  ) async {
    return appendRow(spreadsheetId, '$sheetName!A:Z', model.toSheetRow());
  }

  // Generic method to fetch and map rows to a model
  Future<List<T>> fetchModelRows<T>(
    String spreadsheetId,
    String sheetName,
    T Function(List<dynamic>) fromRow,
  ) async {
    final rows = await getSheetData(spreadsheetId, '$sheetName!A:Z');
    if (rows == null) return [];

    // Skip the header row (assuming first row is header)
    if (rows.length <= 1) return [];

    return rows.skip(1).map((row) => fromRow(row)).toList();
  }

  // Retrieve the Sheet Name from its GID
  Future<String?> getSheetNameFromGid(String spreadsheetId, String gid) async {
    if (_sheetsApi == null) {
      throw Exception('Google Sheets API is not initialized.');
    }

    try {
      final spreadsheet = await _sheetsApi!.spreadsheets.get(
        spreadsheetId,
        $fields: 'sheets.properties',
      );

      final sheetsList = spreadsheet.sheets;
      if (sheetsList == null) return null;

      for (var sheet in sheetsList) {
        if (sheet.properties?.sheetId?.toString() == gid) {
          return sheet.properties?.title;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch sheet name for GID $gid: $e');
    }
  }
}
