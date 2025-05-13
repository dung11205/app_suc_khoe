import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _service = AppointmentService();

  @override
  Widget build(BuildContext context) {
    if (!_service.isUserLoggedIn) {
      return Scaffold(
        body: const Center(child: Text("Bạn chưa đăng nhập")),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Tắt thanh cuộn
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAppointmentDialog(),
          child: const Icon(Icons.add),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getCurrentAppointmentsStream(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  debugPrint("No data yet, loading...");
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint("StreamBuilder error: ${snapshot.error}");
                  return SliverToBoxAdapter(
                    child: Center(child: Text("Lỗi: ${snapshot.error}")),
                  );
                }

                final docs = snapshot.data!.docs;
                debugPrint("Received ${docs.length} current appointments");
                for (var doc in docs) {
                  final data = doc.data();
                  final date = (data['appointmentDate'] as Timestamp).toDate();
                  debugPrint("Appointment: ${data['doctorName']}, Date: $date");
                }

                if (docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text("Chưa có lịch hẹn nào.")),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data();
                      final date = (data['appointmentDate'] as Timestamp).toDate();
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.teal[50],
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: const Icon(Icons.calendar_today, color: Colors.teal),
                          title: Text(
                            "👨‍⚕️ Bác sĩ: ${data['doctorName']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("🗓 Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}"),
                              Text("💬 Triệu chứng: ${data['symptoms']}"),
                            ],
                          ),
                          onTap: () => _showAppointmentDialog(
                            docId: docs[index].id,
                            existingDoctor: data['doctorName'],
                            existingSymptoms: data['symptoms'],
                            existingDateTime: date,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _service.deleteAppointment(
                              docId: docs[index].id,
                              context: context,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDialog({
    String? docId,
    String? existingDoctor,
    String? existingSymptoms,
    DateTime? existingDateTime,
  }) {
    final _formKey = GlobalKey<FormState>();
    final doctorController = TextEditingController(text: existingDoctor ?? '');
    final symptomController = TextEditingController(text: existingSymptoms ?? '');
    DateTime? selectedDateTime = existingDateTime;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(docId == null ? "Tạo lịch hẹn mới" : "Chỉnh sửa lịch hẹn"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    labelText: "Tên bác sĩ",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Không được bỏ trống" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: symptomController,
                  decoration: const InputDecoration(
                    labelText: "Triệu chứng",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Không được bỏ trống" : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.access_time),
                  label: Text(selectedDateTime == null
                      ? "Chọn ngày và giờ"
                      : DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime!)),
                  onPressed: () async {
                    final now = DateTime.now();
                    // Mặc định ngày bắt đầu là ngày mai để đảm bảo thời gian trong tương lai
                    final initialDate = selectedDateTime ?? now.add(const Duration(days: 1));
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: now,
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedDateTime != null
                            ? TimeOfDay.fromDateTime(selectedDateTime!)
                            : TimeOfDay.fromDateTime(now),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate() && selectedDateTime != null) {
                try {
                  if (docId == null) {
                    await _service.createAppointment(
                      doctorName: doctorController.text,
                      symptoms: symptomController.text,
                      appointmentDate: selectedDateTime!,
                      context: context,
                    );
                    _service.showSnack(context, 'Đặt lịch khám thành công');
                  } else {
                    await _service.updateAppointment(
                      docId: docId,
                      doctorName: doctorController.text,
                      symptoms: symptomController.text,
                      appointmentDate: selectedDateTime!,
                      context: context,
                    );
                    _service.showSnack(context, 'Cập nhật lịch thành công');
                  }
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint("Error saving appointment: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi lưu lịch hẹn: ${e.toString()}')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vui lòng điền đầy đủ và chọn thời gian")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}