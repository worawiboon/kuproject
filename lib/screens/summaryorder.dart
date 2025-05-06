import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kuproject/screens/payment.dart';

class Summaryorder extends StatefulWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> orderedItems;
  final String restaurantName;
  final String restaurantId; // เพิ่ม restaurantId
  final String additionalDetails;

  const Summaryorder({
    Key? key,
    required this.totalPrice,
    required this.orderedItems,
    required this.restaurantName,
    required this.restaurantId, // เพิ่ม required
    required this.additionalDetails,
  }) : super(key: key);

  @override
  State<Summaryorder> createState() => _SummaryorderState();
}

class _SummaryorderState extends State<Summaryorder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isProcessing = false;

  Future<String> _createOrder() async {
    try {
      setState(() {
        isProcessing = true;
      });

      // ดึงข้อมูลร้านอาหาร
      final restaurantDoc = await _firestore
          .collection('restuarant')
          .doc(widget.restaurantId)
          .get();

      if (!restaurantDoc.exists) {
        throw Exception('ไม่พบข้อมูลร้านอาหาร');
      }

      // ดึง resid จากข้อมูลร้าน
      String resid = restaurantDoc.get('resid') ?? '';

      // สร้าง orderid แบบ timestamp
      String orderid = 'ORDER${DateTime.now().millisecondsSinceEpoch}';

      // ดึง current user ID
      String stdid = _auth.currentUser?.uid ?? '';

      // บันทึกข้อมูลลง Orderstransaction
      final DocumentReference docRef =
          await _firestore.collection('Orderstransaction').add({
        'orderid': orderid,
        'resid': resid,
        'price': widget.totalPrice,
        'stdid': stdid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'items': widget.orderedItems,
        'additionalDetails': widget.additionalDetails,
      });

      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      throw e;
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 117, 3),
        title: Text('สรุปรายการสั่งซื้อ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ร้าน: ${widget.restaurantName}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายการอาหาร',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...widget.orderedItems.map((item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${item['price']} บาท × ${item['quantity']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item['totalItemPrice']} บาท',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (widget.additionalDetails.isNotEmpty) ...[
                        Divider(thickness: 1),
                        SizedBox(height: 8),
                        Text(
                          'รายละเอียดเพิ่มเติม:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            widget.additionalDetails,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                      Divider(thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ราคารวมทั้งสิ้น',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.totalPrice.toStringAsFixed(2)} บาท',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 7, 117, 3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          try {
                            final orderId = await _createOrder();
                            if (!mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Payment(
                                  totalprice: widget.totalPrice,
                                  orderedItems: widget.orderedItems,
                                  orderId: orderId,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'เกิดข้อผิดพลาดในการสร้างออเดอร์ กรุณาลองใหม่อีกครั้ง'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 7, 117, 3),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'ยืนยันการสั่งซื้อ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'แก้ไขรายการ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
