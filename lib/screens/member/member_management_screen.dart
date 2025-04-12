import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/member/member_form_screen.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';
import 'package:intl/intl.dart';

class MemberManagementScreen extends StatelessWidget {
  final CollectionReference members = FirebaseFirestore.instance.collection(
    'users',
  );

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa thành viên này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Hủy
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Xác nhận
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await doc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thành viên thành công!')),
        );
      } catch (e) {
        print('Error deleting document: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xảy ra lỗi khi xóa thành viên.')),
        );
      }
    }
  }

  // Tính tuổi và thời gian tham gia
  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String calculateMembershipDuration(DateTime joinDate) {
    final now = DateTime.now();
    final years = now.year - joinDate.year;
    final months = now.month - joinDate.month + (years * 12);
    return '$years năm, ${months % 12} tháng';
  }

  Color getMembershipColor(DateTime joinDate) {
    final now = DateTime.now();
    final years = now.year - joinDate.year;
    if (years >= 10) {
      return Colors.red; // Đẳng cấp cao nhất
    } else if (years >= 5) {
      return Colors.orange; // Đẳng cấp trung bình
    } else {
      return Colors.green; // Đẳng cấp thấp
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thành viên'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
                (route) => false,
              ),
        ),
      ),
      body: Column(
        children: [
          // Thêm thông tin tổng số thành viên ở trên top
          StreamBuilder(
            stream: members.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Lỗi khi tải dữ liệu');
              }
              final totalMembers = snapshot.data?.docs.length ?? 0;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tổng số thành viên: $totalMembers',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder(
              stream: members.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Firestore Error: ${snapshot.error}');
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Không có thành viên nào.'));
                }
                return ListView(
                  children:
                      snapshot.data!.docs.map((doc) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MemberFormScreen(member: doc),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        doc['name'],
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Tuổi: ${calculateAge(DateFormat('dd-MM-yyyy').parse(doc['birth_date']))}',
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Số điện thoại: ${doc['phone']}',
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Đã phục vụ: ${calculateMembershipDuration(DateFormat('dd-MM-yyyy').parse(doc['join_date']))}',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: getMembershipColor(
                                        DateFormat(
                                          'dd-MM-yyyy',
                                        ).parse(doc['join_date']),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _showDeleteConfirmDialog(
                                            context,
                                            doc,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MemberFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
