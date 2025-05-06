import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuproject/screens/payment.dart';
import 'package:kuproject/screens/restuarant.dart';
import 'package:kuproject/screens/summaryorder.dart';

class Restaurantscreen extends StatefulWidget {
  final String restaurantId;

  const Restaurantscreen({required this.restaurantId, Key? key})
      : super(key: key);

  @override
  State<Restaurantscreen> createState() => _RestaurantscreenState();
}

class RestaurantData {
  final String id;
  final String name;
  final String description;
  final String resImage;
  final String resid; // เพิ่ม field resid

  RestaurantData({
    required this.id,
    required this.name,
    required this.description,
    required this.resImage,
    required this.resid, // เพิ่ม required field
  });
}

class MenuItemData {
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  int quantity;
  final bool isAvailable;

  MenuItemData({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
    this.quantity = 0,
  });
}

class OrderTransaction {
  final String orderid;
  final String resid;
  final double price;
  final String stdid;
  final String status;
  final List<Map<String, dynamic>> items;
  final DateTime timestamp;

  OrderTransaction({
    required this.orderid,
    required this.resid,
    required this.price,
    required this.stdid,
    required this.status,
    required this.items,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderid': orderid,
      'resid': resid,
      'price': price,
      'stdid': stdid,
      'status': status,
      'items': items,
      'timestamp': timestamp,
    };
  }
}

class _RestaurantscreenState extends State<Restaurantscreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String restaurantName = '';
  String restaurantDescription = '';
  List<MenuItemData> menuItems = [];
  bool isLoading = true;
  double totalPrice = 0;
  List<RestaurantData> restaurants = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _additionalDetailsController =
      TextEditingController();

  Future<String?> getRestaurantResId() async {
    try {
      final restaurantDoc = await _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .get();

      if (restaurantDoc.exists) {
        return restaurantDoc.get('resid') as String?;
      }
      return null;
    } catch (e) {
      print('Error getting resid: $e');
      return null;
    }
  }

  void _checkAuthAndCreateOrder() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนสั่งอาหาร'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // ดำเนินการสั่งอาหารต่อ...
  }

  @override
  void initState() {
    super.initState();
    fetchRestaurantData();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    try {
      print('Starting to fetch restaurants...');
      final QuerySnapshot restaurantSnapshot =
          await _firestore.collection('restuarant').get();

      print('Found ${restaurantSnapshot.docs.length} restaurants');

      final List<RestaurantData> loadedRestaurants = [];

      for (var doc in restaurantSnapshot.docs) {
        print('Processing restaurant: ${doc.id}');
        try {
          loadedRestaurants.add(RestaurantData(
            id: doc.id,
            name: doc.get('resname') as String? ?? 'Unnamed Restaurant',
            description: doc.get('description') as String? ?? 'No description',
            resImage: doc.get('resImage') as String? ?? 'No Image Url',
            resid: doc.get('resid') as String? ?? '', // เพิ่มการดึง resid
          ));
        } catch (e) {
          print('Error processing restaurant ${doc.id}: $e');
        }
      }

      setState(() {
        restaurants = loadedRestaurants;
      });

      print('Successfully loaded ${restaurants.length} restaurants');
    } catch (e) {
      print('Error fetching restaurants: $e');
      throw e;
    }
  }

  Future<void> fetchRestaurantData() async {
    try {
      // Debug logs เพื่อตรวจสอบการเรียกข้อมูล
      print('Attempting to fetch restaurant data...');
      print('Restaurant ID: ${widget.restaurantId}');

      final restaurantDoc = await _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .get();

      // Debug log ตรวจสอบการมีอยู่ของข้อมูลร้านอาหาร
      print('Restaurant exists: ${restaurantDoc.exists}');
      if (restaurantDoc.exists) {
        print('Restaurant data: ${restaurantDoc.data()}');

        setState(() {
          restaurantName = restaurantDoc.get('resname') ?? '';
          restaurantDescription = restaurantDoc.get('description') ?? '';
        });

        // Debug log แสดงชื่อร้านที่ได้
        print('Restaurant Name: $restaurantName');
        print('Restaurant Description: $restaurantDescription');

        final menuSnapshot = await _firestore
            .collection('restuarant')
            .doc(widget.restaurantId)
            .collection('menu')
            .where('isAvailable', isEqualTo: true)
            .get();

        print('Found ${menuSnapshot.docs.length} available menu items');

        // Debug log ตรวจสอบข้อมูลเมนูแต่ละรายการ
        menuSnapshot.docs.forEach((doc) {
          print('Menu item ID: ${doc.id}');
          print('Menu item data: ${doc.data()}');
        });

        final List<MenuItemData> loadedMenuItems = [];

        for (var doc in menuSnapshot.docs) {
          try {
            // Debug log สำหรับการแปลงข้อมูลแต่ละเมนู
            print('Processing menu item: ${doc.id}');
            print('Raw data: ${doc.data()}');

            MenuItemData menuItem = MenuItemData(
              name: doc.get('foodname') ?? '',
              description: doc.get('description') ?? '',
              imageUrl: doc.get('imageUrl') ?? '',
              price: (doc.get('price') ?? 0).toDouble(),
              isAvailable: doc.get('isAvailable') ?? true,
            );

            print('Successfully created MenuItemData for: ${menuItem.name}');
            loadedMenuItems.add(menuItem);
          } catch (error) {
            print('Error processing menu item ${doc.id}: $error');
          }
        }

        setState(() {
          menuItems = loadedMenuItems;
          isLoading = false;
        });
      } else {
        print('Restaurant document does not exist!');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching restaurant data: $e');
      print('Error stack trace: ${StackTrace.current}');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateTotalPrice() {
    setState(() {
      totalPrice =
          menuItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  Widget _buildMenuItemCard(MenuItemData food) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                food.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: Icon(Icons.restaurant, color: Colors.grey[500]),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    food.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${food.price} บาท',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 7, 117, 3),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                  onPressed: food.quantity > 0
                      ? () {
                          setState(() {
                            food.quantity--;
                            _calculateTotalPrice();
                          });
                        }
                      : null,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${food.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  color: const Color.fromARGB(255, 7, 117, 3),
                  onPressed: () {
                    setState(() {
                      food.quantity++;
                      _calculateTotalPrice();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _calculateTotalPrice();

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 7, 117, 3),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 117, 3),
        elevation: 0,
        title: Text('รายการอาหาร'),
      ),
      body: Column(
        children: [
          // ส่วนรูปภาพด้านบน
          Container(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                // รูปภาพร้าน
                Image.network(
                  restaurants.isNotEmpty ? restaurants.first.resImage : '',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('ไม่พบรูปภาพ'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // เพิ่มเอฟเฟค gradient ด้านล่าง
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // ข้อมูลร้าน
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        restaurantDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ส่วนรายการเมนู
          Expanded(
            child: menuItems.isEmpty
                ? Center(
                    child: Text(
                      'ไม่มีรายการอาหารที่พร้อมขาย',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: 8),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      return _buildMenuItemCard(menuItems[index]);
                    },
                  ),
          ),
          // ส่วนด้านล่าง (รายละเอียดเพิ่มเติมและปุ่มยืนยัน)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _additionalDetailsController,
                      decoration: InputDecoration(
                        labelText: 'รายละเอียดเพิ่มเติม (ถ้ามี)',
                        hintText: 'เช่น ไม่ผัก, ไม่เผ็ด, พิเศษ',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ราคารวม:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${totalPrice.toStringAsFixed(2)} บาท',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 7, 117, 3),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: totalPrice > 0
                          ? () {
                              // โค้ดส่วนการนำทางไปหน้า Summaryorder
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Summaryorder(
                                    totalPrice: totalPrice,
                                    orderedItems: menuItems
                                        .where((item) => item.quantity > 0)
                                        .map((item) => {
                                              'name': item.name,
                                              'price': item.price,
                                              'quantity': item.quantity,
                                              'totalItemPrice':
                                                  item.price * item.quantity,
                                            })
                                        .toList(),
                                    restaurantName: restaurantName,
                                    restaurantId: widget.restaurantId,
                                    additionalDetails:
                                        _additionalDetailsController.text
                                            .trim(),
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 117, 3),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(double.infinity, 0),
                      ),
                      child: Text(
                        'ยืนยันการสั่งอาหาร',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
