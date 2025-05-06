// Editrestaurantmenu.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Createmenu extends StatefulWidget {
  final String restaurantId;
  final String userId;

  const Createmenu({
    Key? key,
    required this.restaurantId,
    required this.userId,
  }) : super(key: key);

  @override
  _CreatemenuState createState() => _CreatemenuState();
}

class _CreatemenuState extends State<Createmenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _foodNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _imageUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isNewMenu = false;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot menuSnapshot = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu')
          .get();

      if (menuSnapshot.docs.isNotEmpty) {
        DocumentSnapshot menuDoc = menuSnapshot.docs.first;
        Map<String, dynamic> menuData = menuDoc.data() as Map<String, dynamic>;
        _foodNameController.text = menuData['foodName'] ?? '';
        _descriptionController.text = menuData['description'] ?? '';
        _priceController.text = menuData['price']?.toString() ?? '';
        _imageUrlController.text = menuData['imageUrl'] ?? '';
      } else {
        _isNewMenu = true;
      }
    } catch (e) {
      print('Error loading menu data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveMenuData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isNewMenu) {
        await _firestore
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('menu')
            .add({
          'foodName': _foodNameController.text,
          'description': _descriptionController.text,
          'price': int.parse(_priceController.text),
          'imageUrl': _imageUrlController.text,
        });
      } else {
        await _firestore
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('menu')
            .doc('menu01')
            .update({
          'foodName': _foodNameController.text,
          'description': _descriptionController.text,
          'price': int.parse(_priceController.text),
          'imageUrl': _imageUrlController.text,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu data saved successfully')),
      );
    } catch (e) {
      print('Error saving menu data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Menu'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _foodNameController,
                    decoration: InputDecoration(labelText: 'Menu Name'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Price'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(labelText: 'Image URL'),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _saveMenuData,
                    child: Text(_isNewMenu ? 'Create Menu' : 'Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
