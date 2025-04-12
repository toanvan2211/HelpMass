import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScheduleFormScreen extends StatefulWidget {
  final DocumentSnapshot? schedule;

  const ScheduleFormScreen({Key? key, this.schedule}) : super(key: key);

  @override
  _ScheduleFormScreenState createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isSunday = false;

  List<Map<String, dynamic>> members = [];
  List<String> selectedMembers = [];
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      eventNameController.text = widget.schedule!['event_name'];
      tags = List<String>.from(widget.schedule!['tags'] ?? []);
      selectedDate = DateTime.parse(widget.schedule!['date']);
      selectedTime = TimeOfDay(
        hour: int.parse(widget.schedule!['time'].split(':')[0]),
        minute: int.parse(widget.schedule!['time'].split(':')[1]),
      );
      isSunday = widget.schedule!['isSunday'] ?? false;
      selectedMembers = List<String>.from(widget.schedule!['members']);
    }
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
        isSunday = picked.weekday == DateTime.sunday;
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

  Future<void> _showMemberSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Chọn thành viên trực nhật'),
              content:
                  members.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final isSelected = selectedMembers.contains(
                              member['id'],
                            );
                            return CheckboxListTile(
                              title: Text(member['name']),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
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
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Đóng dialog
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).pop(), // Lưu và đóng dialog
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {}); // Cập nhật giao diện bên ngoài sau khi đóng dialog
  }

  Future<void> saveSchedule() async {
    try {
      // Sửa lỗi khi lưu danh sách thành viên đã chọn
      selectedMembers =
          selectedMembers
              .where((id) => members.any((m) => m['id'] == id))
              .toList();
      if (widget.schedule == null) {
        final docRef = FirebaseFirestore.instance.collection('schedules').doc();
        await docRef.set({
          'id': docRef.id,
          'event_name': eventNameController.text.trim(),
          'date':
              selectedDate != null
                  ? selectedDate!.toIso8601String().split('T')[0]
                  : '',
          'time':
              selectedTime != null
                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                  : '',
          'tags': tags,
          'isSunday': isSunday,
          'members': selectedMembers,
        });
      } else {
        await widget.schedule!.reference.update({
          'event_name': eventNameController.text.trim(),
          'date':
              selectedDate != null
                  ? selectedDate!.toIso8601String().split('T')[0]
                  : widget.schedule!['date'],
          'time':
              selectedTime != null
                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                  : widget.schedule!['time'],
          'tags': tags,
          'isSunday': isSunday,
          'members': selectedMembers,
        });
      }
    } catch (e) {
      print('Error saving schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.schedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa lịch trực' : 'Thêm lịch trực'),
      ),
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
              if (selectedMembers.isNotEmpty)
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
                    Wrap(
                      spacing: 8.0,
                      children:
                          selectedMembers.map((memberId) {
                            final member = members.firstWhere(
                              (m) => m['id'] == memberId,
                              orElse: () => {'name': 'Không xác định'},
                            );
                            return Chip(
                              label: Text(member['name']),
                              backgroundColor: Colors.blue,
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showMemberSelectionDialog(context),
                child: const Text('Chọn thành viên trực nhật'),
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
                  await saveSchedule();
                  Navigator.pop(context);
                },
                child: Text(isEditMode ? 'Lưu' : 'Thêm'),
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
