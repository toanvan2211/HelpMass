import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class EditScheduleScreen extends StatefulWidget {
  final DocumentSnapshot schedule;

  EditScheduleScreen({required this.schedule});

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<Map<String, dynamic>> members = [];
  List<String> selectedMembers = [];
  List<String> tags = []; // List of tags
  bool isSunday = false;

  @override
  void initState() {
    super.initState();
    eventNameController.text = widget.schedule['event_name'];
    tags = List<String>.from(widget.schedule['tags'] ?? []);
    selectedDate = DateTime.parse(widget.schedule['date']);
    selectedTime = TimeOfDay(
      hour: int.parse(widget.schedule['time'].split(':')[0]),
      minute: int.parse(widget.schedule['time'].split(':')[1]),
    );
    isSunday = widget.schedule['isSunday'] ?? false;
    selectedMembers = List<String>.from(widget.schedule['members']);
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      members =
          snapshot.docs
              .map((doc) => {'id': doc.id, 'name': doc['name']})
              .toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isSunday = picked.weekday == DateTime.sunday; // Update isSunday flag
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> updateSchedule() async {
    try {
      await widget.schedule.reference.update({
        'event_name': eventNameController.text.trim(),
        'tags': tags, // Save tags as a list
        'date':
            selectedDate != null
                ? selectedDate!.toIso8601String().split('T')[0]
                : widget.schedule['date'],
        'time':
            selectedTime != null
                ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                : widget.schedule['time'],
        'members': selectedMembers,
        'isSunday': isSunday,
      });
      Navigator.pop(context);
    } catch (e) {
      print('Error updating schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa lịch trực')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: eventNameController,
                decoration: const InputDecoration(labelText: 'Tên sự kiện'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
                      decoration: const InputDecoration(labelText: 'Thêm tag'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (tagController.text.trim().isNotEmpty) {
                        setState(() {
                          tags.add(tagController.text.trim());
                          tagController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 8.0,
                children:
                    tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () {
                              setState(() {
                                tags.remove(tag);
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? 'Ngày: ${DateFormat('dd-MM-yyyy').format(selectedDate!)}'
                          : 'Chọn ngày',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Chọn ngày'),
                  ),
                ],
              ),
              if (selectedDate != null)
                Text(
                  'Ngày trong tuần: ${_getDayOfWeek(selectedDate!.weekday)}',
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedTime != null
                          ? 'Giờ: ${selectedTime!.format(context)}'
                          : 'Chọn giờ',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectTime(context),
                    child: const Text('Chọn giờ'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn thành viên trực nhật:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              members.isEmpty
                  ? const CircularProgressIndicator()
                  : ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isSelected = selectedMembers.contains(member['id']);
                      return CheckboxListTile(
                        title: Text(member['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedMembers.add(member['id']);
                            } else {
                              selectedMembers.remove(member['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (eventNameController.text.isEmpty ||
                      selectedDate == null ||
                      selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập đầy đủ thông tin!'),
                      ),
                    );
                    return;
                  }
                  await updateSchedule();
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return days[weekday - 1];
  }
}
