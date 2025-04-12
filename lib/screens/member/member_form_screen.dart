import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MemberFormScreen extends StatefulWidget {
  final DocumentSnapshot?
  member; // Nếu null, chế độ là "add", nếu không là "edit"

  const MemberFormScreen({Key? key, this.member}) : super(key: key);

  @override
  _MemberFormScreenState createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? birthDate;
  DateTime joinDate = DateTime.now(); // Ngày gia nhập mặc định là ngày hiện tại

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      // Chế độ "edit"
      nameController.text = widget.member!['name'];
      phoneController.text = widget.member!['phone'];
      birthDate = DateFormat('dd-MM-yyyy').parse(widget.member!['birth_date']);
      joinDate = DateFormat('dd-MM-yyyy').parse(widget.member!['join_date']);
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  // Thêm chức năng chỉnh sửa ngày gia nhập
  Future<void> _selectJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: joinDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != joinDate) {
      setState(() {
        joinDate = picked;
      });
    }
  }

  Future<void> saveMember() async {
    try {
      if (widget.member == null) {
        // Chế độ "add"
        final docRef = FirebaseFirestore.instance.collection('users').doc();
        await docRef.set({
          'id': docRef.id,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'birth_date':
              birthDate != null
                  ? DateFormat('dd-MM-yyyy').format(birthDate!)
                  : '01-01-2000', // Giá trị mặc định
          'join_date': DateFormat('dd-MM-yyyy').format(joinDate),
        });
      } else {
        // Chế độ "edit"
        await widget.member!.reference.update({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'birth_date':
              birthDate != null
                  ? DateFormat('dd-MM-yyyy').format(birthDate!)
                  : widget.member!['birth_date'],
          'join_date': DateFormat('dd-MM-yyyy').format(joinDate),
        });
      }
    } catch (e) {
      print('Error saving member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.member != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa thành viên' : 'Thêm thành viên'),
      ),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    birthDate != null
                        ? 'Ngày sinh: ${DateFormat('dd-MM-yyyy').format(birthDate!)}'
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ngày gia nhập: ${DateFormat('dd-MM-yyyy').format(joinDate)}',
                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectJoinDate(context),
                  child: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ thông tin!'),
                    ),
                  );
                  return;
                }
                await saveMember();
                Navigator.pop(context);
              },
              child: Text(isEditMode ? 'Lưu' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
