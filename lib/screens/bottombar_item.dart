import 'package:flutter/material.dart';

class BottomBarItem extends StatelessWidget {
  const BottomBarItem(
    this.icon, {
    this.onTap,
    this.color = const Color.fromARGB(255, 78, 77, 77),
    this.activeColor = const Color.fromARGB(255, 10, 199, 4),
    this.isActive = false,
    this.isNotified = false,
  });

  final IconData icon;
  final Color color;
  final Color activeColor;
  final bool isNotified;
  final bool isActive;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [isNotified ? _buildNotifiedIcon() : _buildIcon()],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(7),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          shape: BoxShape.circle,
          color: isActive
              ? Colors.white.withOpacity(.15)
              : Color.fromARGB(255, 255, 255, 255)),
      child: Icon(
        icon,
        size: 26,
        color: isActive ? activeColor : color,
      ),
    );
  }

  Widget _buildNotifiedIcon() {
    return Stack(
      children: <Widget>[
        Icon(
          icon,
          size: 26,
          color: isActive ? activeColor : color,
        ),
        Positioned(
          top: 5.0,
          right: 0,
          left: 8.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Icon(
              Icons.brightness_1,
              size: 10.0,
              color: Colors.red,
            ),
          ),
        )
      ],
    );
  }
}
