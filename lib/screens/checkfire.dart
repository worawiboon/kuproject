import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kuproject/routes/routes.dart';
import 'package:kuproject/screens/splash_screen.dart';

class CheckFire extends StatefulWidget {
  const CheckFire({super.key});

  @override
  State<CheckFire> createState() => _CheckFireState();
}

class _CheckFireState extends State<CheckFire> {
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: firebase,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                title: Text("Error"),
              ),
              body: Center(
                child: Text("${snapshot.error}"),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              home: SplashScreen(),
            );
          }
          return Scaffold(
            body: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  Text("${snapshot.connectionState}")
                ],
              ),
            ),
          );
        });
  }
}
