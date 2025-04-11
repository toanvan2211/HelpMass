import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditMemberScreen extends StatefulWidget {
  final DocumentSnapshot member;

  EditMemberScreen({required this.member});

  @override
  _EditMemberScreenState createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? birthDate;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.member['name'];
    phoneController.text = widget.member['phone'];
    birthDate = DateTime.parse(widget.member['birth_date']);
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thành viên')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'ID: ${widget.member.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ), // Hiển thị ID
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    birthDate != null
                        ? 'Ngày sinh: ${birthDate!.toLocal()}'.split(' ')[0]
                        : 'Chọn ngày sinh',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectBirthDate(context),
                  child: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await widget.member.reference.update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'birth_date': birthDate?.toIso8601String().split('T')[0],
                });
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
