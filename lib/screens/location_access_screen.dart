import 'package:flutter/material.dart';
import 'package:kuproject/screens/login.dart';
import 'package:kuproject/screens/root.dart';
import 'package:kuproject/screens/menu.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class LocationAccessScreen extends StatefulWidget {
  const LocationAccessScreen({super.key});

  @override
  State<LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<LocationAccessScreen> {
  double widget1Opacity = 0.0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        widget1Opacity = 1;
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(children: [
          Padding(
            padding: EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    children: [
                      AnimatedOpacity(
                        opacity: widget1Opacity,
                        duration: Duration(seconds: 2),
                        child: Image.asset(
                          "images/Logo2.jpg",
                          height: 200,
                        ),
                      ),
                      SizedBox(
                        height: 100,
                      ),
                      AnimatedOpacity(
                        opacity: widget1Opacity,
                        duration: Duration(seconds: 2),
                        child: Text(
                          "Wellcome Ku Na Kub Nong Nong",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: 200,
                      ),
                      AnimatedOpacity(
                        opacity: widget1Opacity,
                        duration: Duration(seconds: 2),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(SwipeablePageRoute(
                                builder: (BuildContext context) => Login(),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Continue",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
