import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ViewAndEditMenu extends StatefulWidget {
  final String restaurantId;

  const ViewAndEditMenu({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  _ViewAndEditMenuState createState() => _ViewAndEditMenuState();
}

class _ViewAndEditMenuState extends State<ViewAndEditMenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = false;
  bool _isNewMenu = false;
  String? _currentMenuId;

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

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
      print('Loading menus for restaurant: ${widget.restaurantId}');
      QuerySnapshot menuSnapshot = await _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .collection('menu')
          .get();

      print('Found ${menuSnapshot.docs.length} menu items');

      if (menuSnapshot.docs.isNotEmpty) {
        _menuItems = menuSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['foodname'] = data['foodname'] ?? 'Untitled';
          data['description'] = data['description'] ?? '';
          data['price'] = data['price'] ?? 0.0;
          data['imageUrl'] = data['imageUrl'] ?? '';
          data['isAvailable'] = data['isAvailable'] ?? true;

          print('Loaded menu item: ${doc.id}');
          print('- foodname: ${data['foodname']}');
          print('- description: ${data['description']}');
          print('- price: ${data['price']}');
          return data;
        }).toList();
      } else {
        _menuItems = [];
      }
    } catch (e) {
      print('Error loading menu data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menu data: ${e.toString()}')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMenuData() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      String foodName = _foodNameController.text.trim();
      String description = _descriptionController.text.trim();
      double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      String imageUrl = _imageUrlController.text.trim();

      if (foodName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a menu name')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final menuData = {
        'foodname': foodName,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'isAvailable': true,
      };

      print('\n--- Save Menu Debug Info ---');
      print('IsNewMenu: $_isNewMenu');
      print('CurrentMenuId: $_currentMenuId');
      print('Menu Data: $menuData');

      final menuRef = _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .collection('menu');

      if (_isNewMenu) {
        print('Creating new menu item...');
        DocumentReference newDoc = await menuRef.add(menuData);
        print('Created new menu with ID: ${newDoc.id}');
      } else {
        print('Updating existing menu item...');
        print('Menu ID being updated: $_currentMenuId');
        if (_currentMenuId != null) {
          await menuRef.doc(_currentMenuId).update(menuData);
          print('Menu updated successfully');
        } else {
          print('Error: No menu ID for update');
          throw Exception('No menu ID available for update');
        }
      }

      await _loadMenuData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu data saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving menu data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving menu data: ${e.toString()}')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMenuAvailability(
      String menuId, bool currentStatus) async {
    try {
      await _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .collection('menu')
          .doc(menuId)
          .update({'isAvailable': !currentStatus});

      await _loadMenuData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus
                ? 'Menu item is now available'
                : 'Menu item is now unavailable'),
          ),
        );
      }
    } catch (e) {
      print('Error toggling menu availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating menu status')),
        );
      }
    }
  }

  Future<void> _deleteMenuItem(String menuId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Deleting menu item: $menuId');
      await _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .collection('menu')
          .doc(menuId)
          .delete();

      print('Menu item deleted successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu item deleted successfully')),
        );
      }
      await _loadMenuData();
    } catch (e) {
      print('Error deleting menu item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting menu item: ${e.toString()}')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMenuItemTile(Map<String, dynamic> menuItem) {
    final String menuId = menuItem['id'] ?? '';
    final String foodName = menuItem['foodname'] ?? 'Untitled';
    final bool isAvailable = menuItem['isAvailable'] ?? true;

    return Dismissible(
      key: Key(menuId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteMenuItem(menuId);
      },
      child: ListTile(
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                menuItem['imageUrl'] ?? 'https://via.placeholder.com/150',
                width: 60.0,
                height: 60.0,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60.0,
                    height: 60.0,
                    color: Colors.grey,
                    child: Icon(Icons.error),
                  );
                },
              ),
            ),
            if (!isAvailable)
              Container(
                width: 60.0,
                height: 60.0,
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    'หมด',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                foodName,
                style: TextStyle(
                  color: isAvailable ? Colors.black : Colors.grey,
                ),
              ),
            ),
            Switch(
              value: isAvailable,
              onChanged: (bool value) {
                _toggleMenuAvailability(menuId, isAvailable);
              },
              activeColor: const Color.fromARGB(255, 7, 117, 3),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              menuItem['description'] ?? '',
              style: TextStyle(
                color: isAvailable ? Colors.grey[600] : Colors.grey,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              'Price: ${menuItem['price']?.toString() ?? '0.0'}',
              style: TextStyle(
                color: isAvailable ? Colors.grey[600] : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                print('\n--- Edit Button Pressed ---');
                print('Menu ID: $menuId');
                print('Food Name: $foodName');

                setState(() {
                  _isNewMenu = false;
                  _currentMenuId = menuId;
                });

                _foodNameController.text = menuItem['foodname'] ?? '';
                _descriptionController.text = menuItem['description'] ?? '';
                _priceController.text = (menuItem['price'] ?? 0.0).toString();
                _imageUrlController.text = menuItem['imageUrl'] ?? '';

                _showEditDialog();
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteMenuItem(menuId),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    print('\n--- Show Edit Dialog ---');
    print('IsNewMenu: $_isNewMenu');
    print('CurrentMenuId: $_currentMenuId');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isNewMenu ? 'Create Menu' : 'Edit Menu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _foodNameController,
                decoration: InputDecoration(
                  labelText: 'Menu Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveMenuData();
              Navigator.of(context).pop();
            },
            child: Text(_isNewMenu ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View and Edit Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              print('\n--- Debug Info ---');
              print('Restaurant ID: ${widget.restaurantId}');
              print('Current Menu ID: $_currentMenuId');
              print('Is New Menu: $_isNewMenu');
              print('Menu Items Count: ${_menuItems.length}');
              _menuItems.forEach((item) {
                print('Menu Item: ${item['id']} - ${item['foodname']}');
              });
              print('----------------\n');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.separated(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuItemTile(_menuItems[index]);
                },
                separatorBuilder: (context, index) => SizedBox(height: 16.0),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('\n--- Add New Menu ---');
          setState(() {
            _isNewMenu = true;
            _currentMenuId = null;
          });
          _foodNameController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _imageUrlController.clear();
          _showEditDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
