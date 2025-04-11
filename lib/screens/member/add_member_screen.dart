import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMemberScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  Future<void> addMember() async {
    try {
      final docRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(); // Tạo ID tự động
      await docRef.set({
        'id': docRef.id, // Lưu ID vào tài liệu
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'birth_date': '2000-01-01', // Giá trị mặc định
        'join_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thành viên')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await addMember();
                Navigator.pop(context);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
