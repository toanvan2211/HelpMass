import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/schedule/schedule_form_screen.dart';
import 'package:flutter_application_1/screens/dashboard_screen.dart';

class ScheduleManagementScreen extends StatelessWidget {
  final CollectionReference schedules = FirebaseFirestore.instance.collection(
    'schedules',
  );

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa lịch trực này?'),
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
          const SnackBar(content: Text('Xóa lịch trực thành công!')),
        );
      } catch (e) {
        print('Error deleting document: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xảy ra lỗi khi xóa lịch trực.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch trực'),
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
      body: StreamBuilder(
        stream:
            schedules
                .orderBy('date', descending: true) // Sắp xếp theo ngày giảm dần
                .orderBy('time', descending: true) // Sắp xếp theo giờ giảm dần
                .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Firestore Error: ${snapshot.error}');
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có lịch trực nào.'));
          }
          return ListView(
            children:
                snapshot.data!.docs.map((doc) {
                  final bool isSunday = doc['isSunday'] ?? false;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ScheduleFormScreen(schedule: doc),
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
                            Text(
                              doc['event_name'],
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Ngày: ${doc['date']} - Giờ: ${doc['time']}',
                              style: const TextStyle(fontSize: 14.0),
                            ),
                            const SizedBox(height: 8.0),
                            if (doc['tags'] != null &&
                                (doc['tags'] as List).isNotEmpty)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    (doc['tags'] as List)
                                        .map((tag) => Chip(label: Text(tag)))
                                        .toList(),
                              ),
                            const SizedBox(height: 8.0),
                            // Hiển thị tên thay vì ID của người trực
                            if (doc['members'] != null &&
                                (doc['members'] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Người trực:',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  FutureBuilder(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .where(
                                              FieldPath.documentId,
                                              whereIn: doc['members'],
                                            )
                                            .get(),
                                    builder: (
                                      context,
                                      AsyncSnapshot<QuerySnapshot> snapshot,
                                    ) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return const Text(
                                          'Lỗi khi tải dữ liệu',
                                        );
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return const Text(
                                          'Không có thành viên nào',
                                        );
                                      }
                                      final memberDocs = snapshot.data!.docs;
                                      return Wrap(
                                        spacing: 8.0,
                                        children:
                                            memberDocs.map((memberDoc) {
                                              return Chip(
                                                label: Text(memberDoc['name']),
                                              );
                                            }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8.0),
                            if (isSunday)
                              const Text(
                                'Chủ Nhật',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
                                    () =>
                                        _showDeleteConfirmDialog(context, doc),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScheduleFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
