import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResOrder extends StatefulWidget {
  final String restaurantId;

  const ResOrder({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<ResOrder> createState() => _ResOrderState();
}

class _ResOrderState extends State<ResOrder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color mainColor = Color.fromARGB(255, 139, 60, 155);
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  String resid = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _loadUserAndRestaurantData();
  }

  // เพิ่มเมธอดใหม่สำหรับโหลดข้อมูล user และร้าน
  Future<void> _loadUserAndRestaurantData() async {
    try {
      // ดึง current user
      final User? currentUser = _auth.currentUser;
      print('Current User ID: ${currentUser?.uid}');

      if (currentUser != null) {
        // ดึงข้อมูล user จาก Firestore
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          print('User Data: ${userDoc.data()}');

          // ดึงข้อมูลร้านโดยใช้ uid ของ user
          final QuerySnapshot restaurantSnap = await _firestore
              .collection('restuarant')
              .where('uid', isEqualTo: currentUser.uid)
              .get();

          print('Found ${restaurantSnap.docs.length} restaurant(s)');

          if (restaurantSnap.docs.isNotEmpty) {
            final restaurantDoc = restaurantSnap.docs.first;
            final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
            print('Restaurant Data: $restaurantData');

            resid = restaurantData['resid'] ?? '';
            print('Found resid: $resid');

            if (resid.isNotEmpty) {
              await _loadOrders();
            } else {
              print('No resid found for this restaurant');
              setState(() {
                isLoading = false;
              });
            }
          } else {
            print('No restaurant found for this user');
            setState(() {
              isLoading = false;
            });
          }
        } else {
          print('User document not found');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('No user currently logged in');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user and restaurant data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // ส่วนของ _loadOrders คงเดิม แต่เพิ่ม debug logs
  Future<void> _loadOrders() async {
    try {
      print('Loading orders for resid: $resid');

      final QuerySnapshot orderSnapshot = await _firestore
          .collection('Orderstransaction')
          .where('resid', isEqualTo: resid)
          .orderBy('timestamp', descending: true)
          .get();

      print('Found ${orderSnapshot.docs.length} orders');

      // Debug: แสดงข้อมูลออเดอร์ที่พบ
      orderSnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Order ID: ${doc.id}');
        print('Order resid: ${data['resid']}');
        print('Order Data: $data');
      });

      List<Map<String, dynamic>> loadedOrders = [];
      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        loadedOrders.add(data);
      }

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String docId, String newStatus) async {
    try {
      await _firestore
          .collection('Orderstransaction')
          .doc(docId)
          .update({'status': newStatus});

      await _loadOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพเดทสถานะสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัพเดทสถานะ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    String studentName = '';
    String studentId = '';

    // เพิ่มฟังก์ชันดึงข้อมูลนักศึกษา
    Future<void> fetchStudentData() async {
      try {
        final studentDoc =
            await _firestore.collection('users').doc(order['stdid']).get();

        if (studentDoc.exists) {
          studentName = '${studentDoc.get('fname')} ${studentDoc.get('lname')}';
          studentId = studentDoc.get('stdid') ?? 'ไม่ระบุรหัสนักศึกษา';
        }
      } catch (e) {
        print('Error fetching student data: $e');
      }
    }

    fetchStudentData().then((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('รายละเอียดออเดอร์: ${order['orderid']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ราคารวม: ${order['price']} บาท'),
                Text('สถานะ: ${order['status']}'),
                Text('รหัสนักศึกษา: ${order['stdid']}'),
                Divider(),
                Text('รายการอาหาร:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...(order['items'] as List).map((item) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                          '${item['name']} x${item['quantity']} = ${item['totalItemPrice']} บาท'),
                    )),
                // เพิ่มส่วนแสดงรายละเอียดเพิ่มเติม
                if (order['additionalDetails'] != null &&
                    order['additionalDetails'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Text('รายละเอียดเพิ่มเติม:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(order['additionalDetails'].toString()),
                      ),
                    ],
                  ),
                if (order['paymentSlip'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Text('หลักฐานการโอนเงิน:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showPaymentSlip(order['paymentSlip']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                        ),
                        child: Text('ดูสลิปการโอนเงิน'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            if (order['status'] == 'pending' && order['paymentSlip'] != null)
              TextButton(
                onPressed: () {
                  _updateOrderStatus(order['docId'], 'preparing');
                  // อัพเดทสถานะการชำระเงินเป็น confirmed
                  _updatePaymentStatus(order['docId'], 'confirmed');
                  Navigator.pop(context);
                },
                child: Text('ยืนยันการชำระเงินและรับออเดอร์'),
                style: TextButton.styleFrom(
                  foregroundColor: mainColor,
                ),
              )
            else if (order['status'] == 'pending')
              TextButton(
                onPressed: () {
                  _updateOrderStatus(order['docId'], 'preparing');
                  Navigator.pop(context);
                },
                child: Text('รับออเดอร์'),
                style: TextButton.styleFrom(
                  foregroundColor: mainColor,
                ),
              ),
            if (order['status'] == 'preparing')
              TextButton(
                onPressed: () {
                  _updateOrderStatus(order['docId'], 'completed');
                  Navigator.pop(context);
                },
                child: Text('เสร็จสิ้น'),
                style: TextButton.styleFrom(
                  foregroundColor: mainColor,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ปิด'),
            ),
          ],
        ),
      );
    });
  }

  void _showPaymentSlip(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: mainColor,
              title: Text('สลิปการโอนเงิน'),
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePaymentStatus(String docId, String newStatus) async {
    try {
      await _firestore
          .collection('Orderstransaction')
          .doc(docId)
          .update({'paymentStatus': newStatus});

      await _loadOrders();
    } catch (e) {
      print('Error updating payment status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัพเดทสถานะการชำระเงิน'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor;
    String statusText;

    switch (order['status']) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'รอดำเนินการ';
        break;
      case 'preparing':
        statusColor = mainColor;
        statusText = 'กำลังเตรียม';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'เสร็จสิ้น';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order['status'];
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order: ${order['orderid']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('ราคารวม: ${order['price']} บาท'),
              if (order['timestamp'] != null)
                Text(
                  'เวลา: ${(order['timestamp'] as Timestamp).toDate().toString()}',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text('รายการออเดอร์'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: mainColor))
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ไม่มีรายการออเดอร์',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(orders[index]);
                    },
                  ),
                ),
    );
  }
}
