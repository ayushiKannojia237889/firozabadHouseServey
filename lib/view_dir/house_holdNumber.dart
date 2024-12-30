

import 'package:firozabadwastemng/view_dir/startsurvey.dart';
import 'package:flutter/material.dart';
import '../appConstants/appconstants.dart';
import '../sqliteFolder/sqlite_model.dart';
import '../sqliteFolder/sqlite_service.dart';
import 'mainscreen.dart';
import 'package:path/path.dart' as path;

class FormDetails extends StatefulWidget {
  final String wkt;

  const FormDetails({
    Key? key,
    this.wkt = '',
  }) : super(key: key);

  @override
  State<FormDetails> createState() => _FormDetailsState();
}

class _FormDetailsState extends State<FormDetails> {
  final TextEditingController houseNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: _buildWidget(),
      onWillPop: () async {
        AppConstants.pageTransition(context, const MainScreen());
        return true;
      },
    );
  }

  Widget _buildWidget() {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Firozabad Survey App',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xff228B22),
        elevation: 4.0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            AppConstants.pageTransition(context, MainScreen());
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your details below',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff228B22),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: houseNumberController,
                    decoration: InputDecoration(
                      labelText: 'Enter House Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Color(0xff228B22)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      // Check if houseNumberController is empty
                      if (houseNumberController.text.isEmpty) {
                        // Show error message if it's empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a house number before submitting.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Do not proceed with submission if empty
                      }

                      // Proceed with saving data if houseNumberController is not empty
                      saveDataOffline();

                      // Show a success message after form submission
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Form Submitted!'),
                          backgroundColor: Color(0xff228B22),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 30.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: const Color(0xff228B22),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // saveDataOffline() async {
  //   SqliteService sqliteService = SqliteService();
  //   await sqliteService.initializeDB();
  //
  //   // Check if the tagged_location already exists
  //   bool exists = await sqliteService.checkTaggedLocationExists(widget.wkt);
  //
  //   if (exists) {
  //     // Show a dialog indicating the duplicate entry
  //     _showDialog(
  //       title: 'Duplicate Entry',
  //       content: 'This house is already marked.',
  //     );
  //   } else {
  //     // Proceed to insert the data if it does not exist
  //     FormData formData = FormData(
  //       tagged_location: widget.wkt,
  //       user_houseNumber: houseNumberController.text,
  //     );
  //
  //     int result = await sqliteService.insertFormData(formData);
  //
  //     if (result > 0) {
  //       _showDialog(
  //         title: 'Submission Successful',
  //         content: 'Your data has been successfully submitted.',
  //         onConfirm: () {
  //           AppConstants.pageTransition(context, StartSurveyScreen());
  //         },
  //       );
  //     } else {
  //       _showDialog(
  //         title: 'Submission Failed',
  //         content: 'There was an error while submitting the data.',
  //         onConfirm: () {
  //           Navigator.pop(context);
  //         },
  //       );
  //     }
  //   }
  // }

  saveDataOffline() async {
    SqliteService sqliteService = SqliteService();
    await sqliteService.initializeDB();

    // Check if the house number already exists
    bool houseNumberExists = await sqliteService.checkHouseNumberExists(houseNumberController.text);

    if (houseNumberExists) {
      // Show dialog if house number already exists
      _showDialog(
        title: 'Duplicate Entry',
        content: 'This house number already exists.',
      );
      return; // Stop further processing
    }

    // Check if the tagged location already exists
    bool locationExists = await sqliteService.checkTaggedLocationExists(widget.wkt);

    if (locationExists) {
      // Show dialog for duplicate location
      _showDialog(
        title: 'Duplicate Entry',
        content: 'This house is already marked.',
      );
      return; // Stop further processing
    }

    // Proceed to insert the data if all checks pass
    FormData formData = FormData(
      tagged_location: widget.wkt,
      user_houseNumber: houseNumberController.text,
    );

    int result = await sqliteService.insertFormData(formData);

    if (result > 0) {
      _showDialog(
        title: 'Submission Successful',
        content: 'Your data has been successfully submitted.',
        onConfirm: () {
          AppConstants.pageTransition(context, StartSurveyScreen());
        },
      );
    } else {
      _showDialog(
        title: 'Submission Failed',
        content: 'There was an error while submitting the data.',
        onConfirm: () {
          Navigator.pop(context);
        },
      );
    }
  }


  // Helper function to show dialogs
  void _showDialog({
    required String title,
    required String content,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onConfirm != null) {
                  onConfirm();
                }
              },
            ),
          ],
        );
      },
    );
  }
}


