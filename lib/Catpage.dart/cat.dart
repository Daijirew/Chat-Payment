import 'package:cloud_firestore/cloud_firestore.dart';

class Cat {
  String name;
  String breed;
  String imagePath;
  Timestamp? birthDate;
  String vaccinations; // เพิ่มฟิลด์ vaccinations

  // ปรับปรุงคอนสตรัคเตอร์
  Cat({
    required this.name,
    required this.breed,
    required this.imagePath,
    this.birthDate,
    required this.vaccinations, // เพิ่ม vaccinations เป็น required parameter
  });

  // ปรับปรุง factory constructor
  factory Cat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print("Raw data from Firestore: $data"); // ดูข้อมูลดิบ

    Cat cat = Cat(
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      imagePath: data['imagePath'] ?? '',
      birthDate: data['birthDate'],
      vaccinations: data['vaccinations'] ?? '',
    );
    print("Created Cat object: $cat"); // ดูว่าสร้าง object สำเร็จไหม
    return cat;
  }
  // ปรับปรุงเมธอด toMap
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'imagePath': imagePath,
      'birthDate': birthDate,
      'vaccinations': vaccinations, // เพิ่มการบันทึกข้อมูล vaccinations
    };
  }
}
