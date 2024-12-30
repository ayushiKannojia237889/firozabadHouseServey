import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sqliteFolder/sqlite_model.dart';
import '../sqliteFolder/sqlite_service.dart';
import '../appConstants/appconstants.dart';
import 'exportToExcel.dart';
import 'homescreen.dart';
import 'mainscreen.dart';

class StartSurveyScreen extends StatefulWidget {
  const StartSurveyScreen({super.key});

  @override
  State<StartSurveyScreen> createState() => _StartSurveyScreenState();
}

class _StartSurveyScreenState extends State<StartSurveyScreen> {
  final SqliteService _sqliteService = SqliteService();

  int _surveyedHouseCount = 0;

  void _showErrorSnackBar(String message) {
    AppConstants.showSnackBar(context, message, Colors.red);
  }

  Future<void> generateAndPreviewExcel(List<Map<String, dynamic>> data) async {
    try {
      final sharedPref = await SharedPreferences.getInstance();
      final userName = sharedPref.getString(HomeScreenState.keyLogin) ?? 'User';

      // Generate a timestamp-based file name for the Excel file
      final now = DateTime.now();
      final formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final excelFileName = '${userName}_Survey_$formattedDate.xlsx';

      // Get the external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        print('Error: Unable to access external storage directory.');
        return;
      }
      final excelFilePath = path.join(directory.path, excelFileName);

      // Generate the Excel file
      final excelExporter = ExportToExcel();
      await excelExporter.exportDataToExcel(data, excelFilePath);

      // Open the file for preview
      File excelFile = File(excelFilePath);
      if (await excelFile.exists()) {
        await OpenFilex.open(excelFilePath); // Opens the Excel file for preview
        print('Excel file previewed successfully.');
      } else {
        print('Error: Excel file does not exist at $excelFilePath');
      }
    } catch (e) {
      print('Error in generateAndPreviewExcel: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSurveyedHouseCount(); // Call the method to get the count
  }

  // Fetch the count of surveyed houses
  Future<void> _fetchSurveyedHouseCount() async {
    try {
      int count = await _sqliteService.getSurveyedHouseCount();
      setState(() {
        _surveyedHouseCount = count;
      });
    } catch (e) {
      print('Error fetching surveyed house count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Firozabad Survey App",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: 16.0), // Adjust the value as needed
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () async {
                // Implement your download functionality here
                List<FormData> formDataList =
                    await _sqliteService.getFormDataList();
                // Check if there are 10 or more rows
                print("Total rows in SQLite: ${formDataList.length}");

                if (formDataList.isEmpty) {
                  _showErrorSnackBar(
                      "No plantation records available to export.");
                  return;
                }

                // Convert the FormData list to a map format for Excel export
                List<Map<String, dynamic>> fiSurveyData =
                    formDataList.map((data) {
                  return {
                    'tagged_location': data.tagged_location,
                    'user_houseNumber': data.user_houseNumber,
                  };
                }).toList();

                try {
                  await generateAndShareExcel(fiSurveyData);
                  print('Excel exported successfully.');
                } catch (e) {
                  print('Error exporting data to Excel: $e');
                }

                print('Download icon pressed');
              },
            ),
          ),
        ],
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff228B22),
        centerTitle: true,
        toolbarHeight: 80,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(15.0),
            bottomRight: Radius.circular(15.0),
          ),
        ),
      ),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Display the surveyed house count inside the body
        Text(
          'Surveyed Houses: $_surveyedHouseCount',
          style: TextStyle(
            fontSize: 30, // Increased font size
            fontWeight: FontWeight.bold, // Bold text
            color: Colors.green, // Green color for the text
            letterSpacing: 1.2, // Add some letter spacing for readability
            fontFamily: 'Roboto', // Change the font family
          ),
        ),

        const SizedBox(height: 20),
        // const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // When the button is pressed, navigate to the next screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MainScreen(), // Replace with your next screen
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff228B22), // Green background color
            foregroundColor: Colors.white, // White text color
            padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 20), // Larger padding for a prominent button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Rounded corners
            ),
            elevation: 8, // Enhanced shadow for a floating effect
            shadowColor: Colors.black54, // Softer shadow color
            textStyle: const TextStyle(
              fontSize: 20, // Slightly larger text size
              fontWeight: FontWeight.w600, // Semi-bold text
              letterSpacing: 1.5, // Added letter spacing for a polished look
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow, // Add an icon for visual appeal
                size: 24,
              ),
              const SizedBox(width: 10), // Space between icon and text
              const Text('Start Survey'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(

          onPressed: () async {
            List<FormData> formDataList =
                await _sqliteService.getFormDataList();
            if (formDataList.isEmpty) {
              _showErrorSnackBar("No Survey records available to preview.");
              return;
            }

            // Convert the FormData list to a map format for Excel preview
            List<Map<String, dynamic>> fiSurveyData = formDataList.map((data) {
              return {
                'tagged_location': data.tagged_location,
                'user_houseNumber': data.user_houseNumber,
              };
            }).toList();

            // Preview the Excel file
             await generateAndPreviewExcel(fiSurveyData);

          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff228B22), // Green background color
            foregroundColor: Colors.white, // White text color
            padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 20), // Larger padding for a prominent button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Rounded corners
            ),
            elevation: 8, // Enhanced shadow for a floating effect
            shadowColor: Colors.black54, // Softer shadow color
            textStyle: const TextStyle(
              fontSize: 20, // Slightly larger text size
              fontWeight: FontWeight.w600, // Semi-bold text
              letterSpacing: 1.5, // Added letter spacing for a polished look
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility, // Preview icon
                size: 24,
                color: Colors.white, // White icon color
              ),
              const SizedBox(width: 10), // Space between icon and text
              const Text('Preview Excel File'),
            ],
          ),
        ),
      ])),
    );
  }

  Future<void> generateAndShareExcel(List<Map<String, dynamic>> data) async {
    try {
      final sharedPref = await SharedPreferences.getInstance();
      final userName = sharedPref.getString(HomeScreenState.keyLogin) ?? 'User';
      // Generate the Excel file
      final excelExporter = ExportToExcel();

      // Generate a timestamp-based file name for the Excel file
      final now = DateTime.now();
      final formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final excelFileName = '${userName}_Survey_$formattedDate.xlsx';

      // Get the external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        print('Error: Unable to access external storage directory.');
        return;
      }
      final excelFilePath = path.join(directory.path, excelFileName);

      // Export the data to Excel
      await excelExporter.exportDataToExcel(data, excelFilePath);

      // Confirm data was written to the file after export
      File excelFile = File(excelFilePath);
      if (await excelFile.exists()) {
        final fileSize = await excelFile.length();
        print('Excel file size after export: $fileSize bytes');

        // Share the Excel file using share_plus
        await Share.shareFiles([excelFile.path],
            text: 'Here is the plantation data file.');

        print('File shared successfully!');
      } else {
        print('Error: Excel file does not exist at $excelFilePath');
        return;
      }

      // Clear the SQLite data after export
      print('Clearing SQLite data...');
      await _sqliteService.clearAllData();
      setState(() {
        _surveyedHouseCount = 0; // Reset UI after clearing
      });
      print('SQLite data cleared successfully.');
    } catch (e) {
      print('Error in generateAndShareExcel: $e');
    }
  }

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    } else {
      print("Storage permission denied.");
      return false;
    }
  }

  void checkFileExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      print("File exists at: $filePath");
    } else {
      print("File does NOT exist at: $filePath");
    }
  }


}
