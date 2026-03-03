import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportUtils {
  static Future<void> exportToCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> data,
  }) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(headers);
      rows.addAll(data);

      String csvData = const CsvEncoder().convert(rows);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported Data: $fileName.csv');
    } catch (e) {
      print('Error exporting to CSV: $e');
    }
  }

  static Future<void> exportToPdf({
    required String fileName,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> data,
  }) async {
    try {
      final pdf = pw.Document();

      // Convert dynamic data to string for PDF plugin
      final tableData = data
          .map((row) => row.map((cell) => cell.toString()).toList())
          .toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: tableData,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(4),
              cellAlignments: {
                for (var i = 0; i < headers.length; i++)
                  i: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported Document: $fileName.pdf');
    } catch (e) {
      print('Error exporting to PDF: $e');
    }
  }
}
