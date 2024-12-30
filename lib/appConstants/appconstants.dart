import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class AppConstants{
  static const String appName = 'Geofence Attendance Application ';

  static String baseURL =
  //"http://14.139.43.115:8090/geofenceapi/";
  //"http://14.139.43.115:8090/geofenceapiAttendance/";
  // live DB
  //"http://14.139.43.115:8090/AttendanceWar/";

      "http://192.168.105.191:8880/gramPanchayt/";

  // SHARED PREFERENCES KEYS
  static const String isLogin = 'isLogin';
  static const String isLoginAdmin = 'isLoginAdmin';

  static const String name = 'name';
  static const String mobileno = 'mobileno';
  static const String emailid = 'emailid';
  static const String division = 'division';
  static const String designation = 'designation';
  static const String pin = 'pin';
  static const String image = 'image';





  static const String latitude = 'latitude';
  static const String longitude = 'longitude';


  //SNACK BAR METHOD
  static showSnackBar(BuildContext context, String msg, Color color) {
    final snackBar = SnackBar(
      // duration: Duration(milliseconds: 1),
      content: Text(
        msg,
        style: TextStyle(
          //fontFamily: GoogleFonts.beVietnamPro().fontFamily,
        ),
      ),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  //PAGE TRANSITION METHOD
  static pageTransition(BuildContext context, Widget child) {
    Navigator.pushReplacement(
      context,
      PageTransition(type: PageTransitionType.bottomToTop, child: child),
    );
  }




}