import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class AppointmentHistoryScreen extends StatelessWidget {
  AppointmentHistoryScreen({super.key});

  final _service = AppointmentService();

  @override
  Widget build(BuildContext context) {
    if (!_service.isUserLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lịch Sử Khám"),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Bạn cần đăng nhập để xem lịch sử",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch Sử Khám"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _service.showSnack(context, "Đã làm mới danh sách lịch sử"),
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getAppointmentHistoryStream(),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            debugPrint("StreamBuilder error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    "Đã xảy ra lỗi: ${snapshot.error}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            debugPrint("No data yet, loading...");
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          debugPrint("Received ${docs.length} appointment history documents");
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có lịch sử khám.",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final date = (data['appointmentDate'] as Timestamp).toDate();
              debugPrint("Displaying appointment: ${data['doctorName']}, Date: $date");

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.blue[50],
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailScreen(appointmentData: data),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(Icons.medical_services, color: Colors.blueAccent),
                  ),
                  title: Text(
                    "Bác sĩ: ${data['doctorName']}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Ngày khám: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      ),
                      Text(
                        "Triệu chứng: ${data['symptoms']}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailScreen({super.key, required this.appointmentData});

  @override
  Widget build(BuildContext context) {
    final date = (appointmentData['appointmentDate'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi Tiết Lịch Hẹn"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: const Icon(Icons.medical_services, size: 30, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "👨‍⚕️ Bác sĩ: ${appointmentData['doctorName']}",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                  title: Text(
                    "Ngày khám: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[800]),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blueAccent),
                  title: Text(
                    "Triệu chứng: ${appointmentData['symptoms']}",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Quay lại"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}