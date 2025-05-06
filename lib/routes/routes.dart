import 'package:flutter/material.dart';
import 'package:kuproject/screens/checkfire.dart';
import 'package:kuproject/screens/fade.dart';
import 'package:kuproject/screens/home.dart';
import 'package:kuproject/screens/login.dart';
import 'package:kuproject/screens/resside/res_main.dart';
import 'package:kuproject/screens/root.dart';
import 'package:kuproject/screens/location_access_screen.dart';
import 'package:kuproject/screens/menu.dart';
import 'package:kuproject/screens/splash_screen.dart';
import 'package:kuproject/screens/userorder.dart';

class Routes {
  static const String menu = '/menu';

  static const String splash = '/splash';
  static const String fade = '/fade';
  static const String root = '/root';
  static const String home = '/home';
  static const String logo = '/logo';
  static const String login = '/login';
  static const String resmain = '/resmain';
  static const String checkfire = '/checkfire';
  static const String userorder = '/userorder';

  static Map<String, WidgetBuilder> get routes {
    return {
      menu: (context) => Menu(),
      logo: (context) => LocationAccessScreen(),
      splash: (context) => SplashScreen(),
      fade: (context) => Fade(title: 'Hello'),
      root: (context) => RootApp(),
      home: (context) => Home(),
      login: (context) => Login(),
      resmain: (context) => ResMain(),
      checkfire: (context) => CheckFire(),
      userorder: (context) => Userorder(),
    };
  }
}
