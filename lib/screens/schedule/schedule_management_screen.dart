import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/schedule/add_schedule_screen.dart';
import 'package:flutter_application_1/screens/schedule/edit_schedule_screen.dart';

class ScheduleManagementScreen extends StatelessWidget {
  final CollectionReference schedules = FirebaseFirestore.instance.collection(
    'schedules',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch trực'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/dashboard'),
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
                              (context) => EditScheduleScreen(schedule: doc),
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
                                onPressed: () async {
                                  try {
                                    await doc.reference.delete();
                                  } catch (e) {
                                    print('Error deleting document: $e');
                                  }
                                },
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
            MaterialPageRoute(builder: (context) => AddScheduleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
