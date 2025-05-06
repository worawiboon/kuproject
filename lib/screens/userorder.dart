import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Userorder extends StatefulWidget {
  const Userorder({super.key});

  @override
  State<Userorder> createState() => _UserorderState();
}

class _UserorderState extends State<Userorder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Color mainColor = Color.fromARGB(255, 7, 117, 3);
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      // เพิ่ม debug logs
      setState(() {
        isLoading = true;
      });

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final String userId = currentUser.uid;
      print('Current User ID: $userId');

      // ดึงข้อมูล Orderstransaction
      final QuerySnapshot orderSnapshot = await _firestore
          .collection('Orderstransaction')
          .where('stdid', isEqualTo: userId)
          .get(); // ลบ orderBy ออกก่อนเพื่อทดสอบ

      print('Found ${orderSnapshot.docs.length} orders');
      print('Order documents: ${orderSnapshot.docs.map((doc) => doc.data())}');

      List<Map<String, dynamic>> loadedOrders = [];

      for (var doc in orderSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('Processing order: ${doc.id}');
          print('Order data: $data');

          // ดึงข้อมูลร้านอาหาร
          if (data['resid'] != null) {
            final QuerySnapshot restaurantSnap = await _firestore
                .collection('restuarant')
                .where('resid', isEqualTo: data['resid'])
                .get();

            print(
                'Restaurant query result: ${restaurantSnap.docs.length} docs found for resid: ${data['resid']}');

            if (restaurantSnap.docs.isNotEmpty) {
              data['restaurantName'] = restaurantSnap.docs.first.get('resname');
              print('Restaurant name found: ${data['restaurantName']}');
            } else {
              data['restaurantName'] = 'ไม่พบข้อมูลร้านอาหาร';
            }
          }

          data['docId'] = doc.id;
          loadedOrders.add(data);
          print('Successfully added order to list');
        } catch (err) {
          print('Error processing order document: $err');
        }
      }

      print('Final loaded orders count: ${loadedOrders.length}');

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      print('Error in _loadOrders: $e');
      print(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียดออเดอร์: ${order['orderid']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ร้านอาหาร: ${order['restaurantName']}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('ราคารวม: ${order['price']} บาท'),
              Text('สถานะ: ${_getStatusText(order['status'])}'),
              if (order['paymentStatus'] != null)
                Text(
                    'สถานะการชำระเงิน: ${_getPaymentStatusText(order['paymentStatus'])}'),
              Divider(),
              Text('รายการอาหาร:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...(order['items'] as List).map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                        '${item['name']} x${item['quantity']} = ${item['totalItemPrice']} บาท'),
                  )),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
        ],
      ),
    );
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'preparing':
        return 'กำลังเตรียมอาหาร';
      case 'completed':
        return 'เสร็จสิ้น';
      default:
        return status;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'waiting_confirmation':
        return 'รอการยืนยันการชำระเงิน';
      case 'confirmed':
        return 'ยืนยันการชำระเงินแล้ว';
      default:
        return status;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor;
    String statusText = _getStatusText(order['status']);

    switch (order['status']) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'preparing':
        statusColor = mainColor;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
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
              Text(
                order['restaurantName'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order: ${order['orderid']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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
    print('Building UserOrder widget');
    print('Orders count: ${orders.length}');
    print('Is Loading: $isLoading');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text("ประวัติการสั่งซื้อ"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              print('Refresh pressed');
              _loadOrders();
            },
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
                        'ไม่มีประวัติการสั่งซื้อ',
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
                      final order = orders[index];
                      print(
                          'Building order card for index $index: ${order['orderid']}');
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }
}
