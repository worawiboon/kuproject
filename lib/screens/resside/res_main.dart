// ResMain.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuproject/main.dart';
import 'package:kuproject/screens/resside/Createmenu.dart';
import 'package:kuproject/screens/resside/resorder.dart';
import 'package:kuproject/screens/resside/viewAndeditmenu.dart';

class ResMain extends StatefulWidget {
  const ResMain({super.key});

  @override
  State<ResMain> createState() => _ResMainState();
}

class _ResMainState extends State<ResMain> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  Future<void> getUserName() async {
    try {
      // Get current user
      final User? user = _auth.currentUser;
      if (user != null) {
        // Get user document from Firestore
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            // Get fname field from document
            userName = userDoc.get('fname') ?? "User";

            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        userName = "User";
        isLoading = false;
      });
    }
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 139, 60, 155),
              size: 40,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Hello, $userName!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 139, 60, 155),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            'https://i.pinimg.com/736x/35/0f/4e/350f4ec1a96aa795bbed4ba44eb54e3c.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        // _buildMenuItem(Icons.restaurant_menu, 'เมนูอาหาร', () {
                        //   // Get the current user's ID
                        //   String restaurantId = userId;

                        //   // Navigate to Editrestaurantmenu screen
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => Createmenu(
                        //         restaurantId: restaurantId,
                        //         userId: userId,
                        //       ),
                        //     ),
                        //   );
                        // }),
                        _buildMenuItem(Icons.list_alt, 'ออเดอร์', () {
                          // TODO Navigate to order screen
                          String restaurantId = userId;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResOrder(
                                restaurantId: restaurantId,
                              ),
                            ),
                          );
                        }),
                        _buildMenuItem(Icons.edit, 'แก้ไขข้อมูล', () {
                          String restaurantId = userId;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewAndEditMenu(
                                restaurantId: userId,
                              ),
                            ),
                          );
                          // Navigate to edit information screen
                        }),
                        _buildMenuItem(
                          Icons.logout,
                          'ออกจากระบบ',
                          () {
                            _auth.signOut();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => MyApp()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
