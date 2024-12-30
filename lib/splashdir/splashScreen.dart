import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_dir/homescreen.dart';
import '../view_dir/startsurvey.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => SplashscreenState();
}

class SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  static const String keyLogin = 'LoginUserName';
  bool? loggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    // Fade-in text and icon animation
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navigate based on login status after a delay
    Timer(const Duration(seconds: 3), () {
      if (loggedIn == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StartSurveyScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    final sharedPref = await SharedPreferences.getInstance();
    final username = sharedPref.getString(keyLogin);
    loggedIn = username != null && username.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/wastecoll.png',
              fit: BoxFit.cover,
            ),
          ),
          // Centered text with fade-in animation
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(seconds: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SafaiMitra Firozabad',
                      style: TextStyle(
                        color: Color(0xff023020),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/fb.png',
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Loading spinner at the bottom center
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SpinKitSpinningLines(
                color: Colors.orange,
                size: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
