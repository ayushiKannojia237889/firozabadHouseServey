import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class ExportToExcel {
  final Uuid uuid = Uuid();

  Future<void> exportDataToExcel(List<Map<String, dynamic>> data, String excelFilePath) async {
    if (data.isEmpty) {
      print('No data to export');
      return;
    }

    // Create a new Excel document
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];

    // Add header row
    sheet.getRangeByName('A1').setValue('tagged_location');
    sheet.getRangeByName('B1').setValue('user_houseNumber');
    print(
        'tagged_location\tuser_houseNumber');

    // Populate data
    for (int i = 0; i < data.length; i++) {
      final row = i + 2;
      sheet.getRangeByName('A$row').setValue(data[i]['tagged_location']);
      sheet.getRangeByName('B$row').setValue(data[i]['user_houseNumber']);
      print(
          '${data[i]['tagged_location']}\t${data[i]['user_houseNumber']}'

      );

    }




    try {
      // Save the document
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Write the Excel file to the specified path
      final File file = File(excelFilePath);
      await file.writeAsBytes(bytes);
      print('File saved to: ${file.path}');
    } catch (e) {
      print('Error exporting data to Excel: $e');
    }
  }
}

