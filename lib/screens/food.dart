import 'package:flutter/material.dart';

class Food {
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  int quantity = 0;

  Food({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}
