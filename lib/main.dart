import 'package:kuproject/routes/routes.dart';
import 'package:kuproject/screens/checkfire.dart';
import 'package:kuproject/screens/resside/res_main.dart';
import 'package:kuproject/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(MyApp());

  // try {
  //   await Firebase.initializeApp();
  //   runApp(MyApp());
  // } catch (error) {
  //   // จัดการข้อผิดพลาด เช่น แสดงข้อความแจ้งเตือนผู้ใช้
  //   print('Error initializing Firebase: $error');
  // }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
// TODO แก้ BYPass เข้าฝั่งร้านค้าเอาไว้
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Routes.checkfire,
      routes: Routes.routes,
      debugShowCheckedModeBanner: false,
      title: "FoodKU",
      // home: SplashScreen(),
    );
  }
}
