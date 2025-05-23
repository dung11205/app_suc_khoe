import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class AppointmentBookingScreen extends StatelessWidget {
  AppointmentBookingScreen({super.key});

  final _service = AppointmentService();
  final _formKey = GlobalKey<FormState>();
  final doctorController = TextEditingController();
  final symptomController = TextEditingController();
  DateTime? selectedDateTime;

  void _showAppointmentDialog(BuildContext context) {
    if (!_service.isUserLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn cần đăng nhập để đặt lịch hẹn")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Tạo lịch hẹn mới"),
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
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Không ược bỏ trống" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: symptomController,
                  decoration: const InputDecoration(
                    labelText: "Triệu chứng",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Không được bỏ trống" : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.access_time),
                  label: Text(selectedDateTime == null
                      ? "Chọn ngày và giờ"
                      : DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime!)),
                  onPressed: () async {
                    final now = DateTime.now();
                    final initialDate = now.add(const Duration(days: 1));
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: now,
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
                      );
                      if (pickedTime != null) {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
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
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate() && selectedDateTime != null) {
                try {
                  await _service.createAppointment(
                    doctorName: doctorController.text,
                    symptoms: symptomController.text,
                    appointmentDate: selectedDateTime!,
                    context: context,
                  );
                  Navigator.pop(context); // Đóng dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bạn đã đặt lịch thành công"),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  // Reset form
                  doctorController.clear();
                  symptomController.clear();
                  selectedDateTime = null;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi khi lưu lịch hẹn: $e")),
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

  @override
  Widget build(BuildContext context) {
    if (!_service.isUserLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đặt hẹn khám'),
          backgroundColor: Colors.cyan,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Bạn cần đăng nhập để đặt lịch hẹn",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Tắt thanh cuộn
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đặt hẹn khám'),
          backgroundColor: Colors.cyan,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAppointmentDialog(context),
          backgroundColor: Colors.purple[200],
          child: const Icon(Icons.add),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // children: [
                  //   Text(
                  //     "Lịch hẹn của bạn",
                  //     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  //           color: Colors.cyan,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //   ),
                  //   const SizedBox(height: 8),
                  //   Text(
                  //     "Xem các lịch hẹn sắp tới hoặc nhấn nút (+) để tạo mới.",
                  //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  //   ),
                  //   const SizedBox(height: 16),
                  // ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getCurrentAppointmentsStream(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text("Lỗi: ${snapshot.error}")),
                  );
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "Chưa có lịch hẹn nào.",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Nhấn nút (+) để đặt lịch hẹn mới.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data();
                      final date = (data['appointmentDate'] as Timestamp).toDate();
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        color: Colors.cyan[50],
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🧑‍⚕️ Bác sĩ: ${data['doctorName']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "📅 Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "💬 Triệu chứng: ${data['symptoms']}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _service.deleteAppointment(
                                  docId: docs[index].id,
                                  context: context,
                                ),
                              ),
                            ],
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
}