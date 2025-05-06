import 'package:flutter/material.dart';
import 'package:kuproject/screens/food.dart';

// นิยาม Object Class
class Restuarant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<Food> foodmenu;
  Restuarant(
      {required this.id,
      required this.name,
      required this.description,
      required this.imageUrl,
      required this.foodmenu});
}

List<Restuarant> restuarants = [
  Restuarant(
    id: '1',
    name: 'ครัวเพียงใจ',
    description: 'อาหารตามสั่งแสนอร่อย',
    imageUrl:
        'https://i.pinimg.com/736x/35/0f/4e/350f4ec1a96aa795bbed4ba44eb54e3c.jpg',
    foodmenu: [
      Food(
          name: 'ข้าวผัดกระเพรา',
          price: 50,
          description: 'อร่อยมาก',
          imageUrl: 'https://s.isanook.com/wo/0/ud/36/180929/f.jpg'),
      Food(
          name: 'ผัดซีอิ๊ว',
          price: 60,
          description: 'หอมอร่อย',
          imageUrl:
              'https://s359.kapook.com/pagebuilder/1958331d-f82e-47eb-9bf3-8b7124e5c330.jpg'),
      Food(
          name: 'ข้าวผัดหมู',
          price: 50,
          description: 'อร่อยมาก',
          imageUrl:
              'https://s359.kapook.com/pagebuilder/008cf2f0-5887-44f4-958f-545ed8b75780.jpg'),
      Food(
          name: 'ผัดคะน้าหมูกรอบ',
          price: 60,
          description: 'หอมอร่อย',
          imageUrl:
              'https://img.wongnai.com/p/1968x0/2019/10/04/07b562224a534e62874602a2a1e71e1a.jpg'),
      Food(
          name: 'ข้าวผัดต้มยำ',
          price: 50,
          description: 'อร่อยมาก',
          imageUrl: '...'),
      Food(
          name: 'แกงจืด',
          price: 60,
          description: 'หอมอร่อย',
          imageUrl:
              'https://www.hongthongrice.com/v2/wp-content/uploads/2017/02/HTR-10Fried-Rice-7.jpg'),
      // เพิ่มรายการเมนูอาหารอื่นๆ
    ],
  ),
  Restuarant(
      id: '2',
      name: 'ปอเป็ด',
      description: 'ข้าวหน้าเป็ดข้าวหมูกรอบข้าวหมูแดงและอาหารตามสั่ง',
      imageUrl:
          'https://cdn.pixabay.com/photo/2023/09/21/10/55/food-8266439_640.jpg',
      foodmenu: [
        Food(
            name: 'ข้าวหน้าเป็ด',
            price: 60,
            description: 'ขายดี',
            imageUrl: '...'),
        Food(
            name: 'ข้าวหมูแดง',
            price: 60,
            description: 'ขายดี',
            imageUrl: '...'),
        Food(
            name: 'ข้าวหมูกรอบ',
            price: 60,
            description: 'ขายดี',
            imageUrl: '...')
      ]),
  Restuarant(
      id: '3',
      name: 'หม่าล่า',
      description: 'หม่าล่าชาบู',
      imageUrl: 'https://media.timeout.com/images/105763156/750/422/image.jpg',
      foodmenu: [
        Food(
            name: 'Set หม่าล่า XL',
            price: 199,
            description: 'ขายดี',
            imageUrl: '...'),
        Food(
            name: 'Set หม่าล่า L',
            price: 159,
            description: 'ขายดี',
            imageUrl: '...'),
        Food(
            name: 'Set หม่าล่า M',
            price: 109,
            description: 'ขายดี',
            imageUrl: '...')
      ]),
  Restuarant(
      id: '4',
      name: 'ของทอด',
      description: 'ของทอดและของกินเล่น',
      imageUrl: 'https://img.lovepik.com/photo/50089/7506.jpg_wh860.jpg',
      foodmenu: [
        Food(name: 'ไก่ป้อป', price: 40, description: 'ขายดี', imageUrl: '...'),
        Food(
            name: 'เฟรนช์ฟรายชีสดิป',
            price: 49,
            description: 'ขายดี',
            imageUrl: '...'),
        Food(name: 'ชีสบอล', price: 40, description: 'ขายดี', imageUrl: '...')
      ]),
  Restuarant(
      id: '5',
      name: 'น้ำหวานขนม',
      description: 'น้ำหวานขนม',
      imageUrl:
          'https://images.hungryhub.com/uploads/review/cover/63450/Hungry-Hub-The-Local-Cover-1024x683.jpg',
      foodmenu: [
        Food(
            name: 'แดงมะนาวโซดา',
            price: 30,
            description: 'ขายดี',
            imageUrl: '...'),
        Food(name: 'เก๊กฮวย', price: 30, description: 'ขายดี', imageUrl: '...'),
        Food(name: 'ไมโล', price: 30, description: 'ขายดี', imageUrl: '...'),
      ]),
];

List<Restuarant> getData() {
  return restuarants;
}

// ฟังก์ชันสร้าง Card จาก Product Object
Widget buildRestuarantCard(Restuarant restuarant) {
  return Card(
    margin: EdgeInsets.all(10),
    child: Column(
      children: [
        Container(
          height: 200,
          width: 500,
          child: Row(
            children: [
              Image.network(
                  'https://img.wongnai.com/p/1920x0/2019/02/08/91f0642b2fe14a839cbb3c5acb456264.jpg'),
              Column(
                children: [
                  Container(
                    height: 100,
                    child: Text(
                      restuarant.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 25, height: 3),
                    ),
                  ),
                  Container(
                    child: Text(
                      restuarant.description,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    ),
  );
}
