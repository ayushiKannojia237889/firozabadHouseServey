import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_dir/startsurvey.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  static const String keyLogin = 'LoginUserName';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White heading
          ),
        ),
        centerTitle: true,
        elevation: 8,
        backgroundColor: const Color(0xff228B22), // Teal AppBar color
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Rounded bottom corners for AppBar
          ),
        ),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Enter Your Name",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff228B22),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Color(0xff228B22)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1), // Semi-transparent input field
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                    borderSide: const BorderSide(color: Color(0xff228B22)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xff228B22)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xff228B22)),
                  ),
                ),
                style: const TextStyle(color: Color(0xff228B22)), // White text color
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final sharedPref = await SharedPreferences.getInstance();
                  await sharedPref.setString(keyLogin, _nameController.text);

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const StartSurveyScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: Colors.white, // White button background
                  foregroundColor: const Color(0xff228B22), // Teal text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded button corners
                  ),
                  elevation: 8, // Button shadow
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
