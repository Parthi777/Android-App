import 'dart:io';
import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

Future<void> main() async {
  final scopes = [sheets.SheetsApi.spreadsheetsReadonlyScope];
  final credentialsFile = File('assets/credentials.json');
  final jsonString = await credentialsFile.readAsString();
  final credentials = ServiceAccountCredentials.fromJson(jsonString);
  final client = await clientViaServiceAccount(credentials, scopes);
  final sheetsApi = sheets.SheetsApi(client);

  final spreadsheetId = '1HYtgy4pLdQkCAInxucl3UT08B9afcJwuSrNtCvgDB7g';
  final response = await sheetsApi.spreadsheets.values.get(
    spreadsheetId,
    'Sold!A:Z',
  );

  final values = response.values;
  if (values == null) {
    print('No data found.');
    return;
  }
  print('Total rows returned by API: ' + values.length.toString());

  if (values.length > 23) {
    for (int i = 20; i < values.length; i++) {
      if (values[i].isNotEmpty) {
        print(
          'Row ' +
              (i + 1).toString() +
              ': ' +
              values[i][0].toString() +
              ' length: ' +
              values[i].length.toString(),
        );
      } else {
        print('Row ' + (i + 1).toString() + ': EMPTY');
      }
    }
  }
}
