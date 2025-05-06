import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuproject/screens/restaurantscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// ข้อมูลร้านอาหาร
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

// ข้อมูลอาหารแนะนำ
class RecommendedFood {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String foodName;
  final String description;
  final double price;
  final String imageUrl;

  RecommendedFood({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.foodName,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<RestaurantData> restaurants = [];
  List<RecommendedFood> recommendedFoods = [];
  String _searchQuery = '';
  String _userName = '';
  Map<String, int> queueCounts = {};

  List<RestaurantData> get filteredRestaurants =>
      restaurants.where((restaurant) {
        final query = _searchQuery.toLowerCase();
        return restaurant.name.toLowerCase().contains(query) ||
            restaurant.description.toLowerCase().contains(query);
      }).toList();

  @override
  void initState() {
    super.initState();
    fetchRestaurantsAndRecommendations();
    fetchUserData();

    Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadQueueCounts();
      }
    });
  }

  @override
  void dispose() {
    // คำสั่งอื่นๆ ใน dispose (ถ้ามี)
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        setState(() {
          _userName = userSnapshot.get('fname') as String? ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _loadQueueCounts() async {
    try {
      // ดึงข้อมูลสำหรับทุกร้าน
      for (var restaurant in restaurants) {
        print(
            'Checking queues for restaurant: ${restaurant.name} (resid: ${restaurant.resid})');

        // ดึงข้อมูล orders ที่ยังไม่เสร็จของแต่ละร้าน
        final QuerySnapshot orderSnapshot = await _firestore
            .collection('Orderstransaction')
            .where('resid', isEqualTo: restaurant.resid) // ใช้ resid แทน id
            .where('status', whereIn: ['pending', 'preparing']).get();

        print('Found ${orderSnapshot.docs.length} pending/preparing orders');
        print(
            'Order IDs: ${orderSnapshot.docs.map((doc) => doc.id).join(', ')}');

        setState(() {
          queueCounts[restaurant.id] = orderSnapshot.docs.length;
        });

        print(
            'Updated queue count for ${restaurant.name}: ${queueCounts[restaurant.id]}');
      }
    } catch (e) {
      print('Error loading queue counts: $e');
      print(e.toString());
    }
  }

  Future<void> fetchRestaurantsAndRecommendations() async {
    try {
      setState(() {
        isLoading = true;
        recommendedFoods = [];
      });

      await fetchRestaurants();
      await _loadQueueCounts(); // เพิ่มการโหลดข้อมูลคิว

      if (restaurants.isNotEmpty) {
        await fetchRecommendedFoods();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> fetchRecommendedFoods() async {
    try {
      print('Starting to fetch recommended foods...');
      List<RecommendedFood> allFoods = [];

      for (var restaurant in restaurants) {
        print('Fetching menu for restaurant: ${restaurant.name}');

        final menuSnapshot = await _firestore
            .collection('restuarant')
            .doc(restaurant.id)
            .collection('menu')
            .where('isAvailable', isEqualTo: true)
            .get();

        for (var menuDoc in menuSnapshot.docs) {
          try {
            allFoods.add(RecommendedFood(
              id: menuDoc.id,
              restaurantId: restaurant.id,
              restaurantName: restaurant.name,
              foodName: menuDoc.get('foodname') ?? '',
              description: menuDoc.get('description') ?? '',
              price: (menuDoc.get('price') ?? 0).toDouble(),
              imageUrl:
                  menuDoc.get('imageUrl') ?? 'https://via.placeholder.com/150',
            ));
          } catch (e) {
            print('Error processing menu item ${menuDoc.id}: $e');
          }
        }
      }

      print('Found ${allFoods.length} total menu items');

      if (allFoods.isNotEmpty) {
        final random = Random();
        final numberOfRecommendations = min(5, allFoods.length);
        List<RecommendedFood> selectedFoods = [];

        while (selectedFoods.length < numberOfRecommendations) {
          final randomIndex = random.nextInt(allFoods.length);
          selectedFoods.add(allFoods[randomIndex]);
          allFoods.removeAt(randomIndex);
        }

        setState(() {
          recommendedFoods = selectedFoods;
        });

        print('Selected ${recommendedFoods.length} recommended foods');
      } else {
        print('No foods available for recommendations');
      }
    } catch (e) {
      print('Error fetching recommended foods: $e');
      throw e;
    }
  }

  Widget buildRecommendationsSection() {
    if (recommendedFoods.isEmpty) {
      return Container(
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                'แนะนำสำหรับคุณ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text('ไม่มีรายการแนะนำในขณะนี้'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              'แนะนำสำหรับคุณ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              scrollDirection: Axis.horizontal,
              itemCount: recommendedFoods.length,
              itemBuilder: (context, index) {
                return buildRecommendationCard(recommendedFoods[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecommendationCard(RecommendedFood food) {
    return Container(
      margin: EdgeInsets.all(5.0),
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Restaurantscreen(
                restaurantId: food.restaurantId,
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  food.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey[500],
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.foodName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    SizedBox(height: 2),
                    Text(
                      '${food.price} บาท',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 7, 117, 3),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(RestaurantData restaurant) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Restaurantscreen(
                    restaurantId: restaurant.id,
                  ),
                ),
              );
            },
            child: Container(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Image.network(
                          restaurant.resImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No Image'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              restaurant.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Restaurantscreen(
                                      restaurantId: restaurant.id,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 7, 117, 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'ดูเมนู',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 7, 117, 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'คิว: ${queueCounts[restaurant.id] ?? 0}', // แสดงจำนวนคิว
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 117, 3),
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                child: Text(
                  'Hello ${_userName}',
                  style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRestaurantsAndRecommendations,
              child: Column(
                children: [
                  // ส่วนแสดงอาหารแนะนำ
                  buildRecommendationsSection(),

                  // ส่วนแสดงรายการร้านอาหาร
                  Expanded(
                    child: filteredRestaurants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('ไม่พบข้อมูลร้านอาหาร'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(top: 8, bottom: 16),
                            itemCount: filteredRestaurants.length,
                            itemBuilder: (context, index) {
                              return _buildRestaurantCard(
                                  filteredRestaurants[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
