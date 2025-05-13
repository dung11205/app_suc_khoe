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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 60, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                "Bạn cần đăng nhập để xem lịch sử",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
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
          title: const Text("Lịch Sử Khám"),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _service.showSnack(context, "Đã làm mới danh sách lịch sử"),
              tooltip: "Làm mới",
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Hiệu ứng nảy, giới hạn cuộn khi ít dữ liệu
          slivers: [
            StreamBuilder<QuerySnapshot>(
              stream: _service.getAppointmentHistoryStream(),
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("StreamBuilder error: ${snapshot.error}");
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                          const SizedBox(height: 20),
                          Text(
                            "Đã xảy ra lỗi: ${snapshot.error}",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  debugPrint("No data yet, loading...");
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                debugPrint("Received ${docs.length} appointment history documents");
                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_toggle_off, size: 60, color: Colors.blueGrey),
                          const SizedBox(height: 20),
                          Text(
                            "Chưa có lịch sử khám.",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blueGrey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Lịch sử sẽ hiển thị sau khi bạn hoàn thành khám.",
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
                      final data = docs[index].data() as Map<String, dynamic>;
                      final date = (data['appointmentDate'] as Timestamp).toDate();
                      debugPrint("Displaying appointment: ${data['doctorName']}, Date: $date");

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.blue[100],
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentDetailScreen(appointmentData: data),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.2),
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
                              const SizedBox(height: 6),
                              Text(
                                "Ngày khám: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                              ),
                              Text(
                                "Triệu chứng: ${data['symptoms']}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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