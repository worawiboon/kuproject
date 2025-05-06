import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Menu(),
    );
  }
}

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Menu"),
      ),
      body: Container(
        child: Container(
          width: double.maxFinite,
          height: 200,
          padding: EdgeInsets.all(50),
          margin: new EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              style: BorderStyle.solid,
              width: 3.0,
            ),
            color: Color.fromARGB(255, 245, 242, 242),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}
