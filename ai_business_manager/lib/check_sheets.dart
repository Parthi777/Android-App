import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;

void main() async {
  final scopes = [sheets.SheetsApi.spreadsheetsScope];
  final jsonString = File('assets/credentials.json').readAsStringSync();
  final credentials = ServiceAccountCredentials.fromJson(jsonString);
  final client = await clientViaServiceAccount(credentials, scopes);
  final sheetsApi = sheets.SheetsApi(client);

  final spreadsheetId = '1HYtgy4pLdQkCAInxucl3UT08B9afcJwuSrNtCvgDB7g';
  
  final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId, $fields: 'sheets.properties');
  for (var sheet in spreadsheet.sheets ?? []) {
    final title = sheet.properties?.title;
    if (title != null) {
      print('--- $title ---');
      try {
        final data = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$title!A1:Z1');
        print(data.values?.firstOrNull ?? 'No data in row 1');
      } catch (e) {
        print('Error: $e');
      }
    }
  }
  exit(0);
}
