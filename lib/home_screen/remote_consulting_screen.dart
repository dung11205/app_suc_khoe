import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_apps/home_screen/chatbot_consultation_screen.dart';
import 'package:intl/intl.dart';

class RemoteConsultingScreen extends StatefulWidget {
  const RemoteConsultingScreen({super.key});

  @override
  State<RemoteConsultingScreen> createState() => _RemoteConsultingScreenState();
}

class _RemoteConsultingScreenState extends State<RemoteConsultingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symptomController = TextEditingController();

  Future<void> _startChatbotConsultation() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotConsultationScreen(
          name: _nameController.text.trim(),
          symptom: _symptomController.text.trim(),
        ),
      ),
    );

    _nameController.clear();
    _symptomController.clear();
  }

  Future<void> _deleteRequest(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('remote_consulting_requests')
          .doc(documentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa yêu cầu thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa yêu cầu: $e')),
      );
    }
  }

  Future<void> _markAsCompleted(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('remote_consulting_requests')
          .doc(documentId)
          .update({'status': 'completed'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu yêu cầu là hoàn thành')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tư vấn từ xa'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điền thông tin tư vấn',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Họ tên',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _symptomController,
                        decoration: InputDecoration(
                          labelText: 'Triệu chứng gặp phải',
                          prefixIcon: const Icon(Icons.medical_services),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Vui lòng mô tả triệu chứng'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _startChatbotConsultation,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Bắt đầu tư vấn với Chatbot'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const Text(
              'Yêu cầu tư vấn gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('remote_consulting_requests')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('Chưa có yêu cầu nào'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final documentId = docs[index].id;
                    final status = data['status'] ?? 'pending';
                    final date = (data['timestamp'] as Timestamp).toDate();
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                    final doctorResponse = data['doctorResponse'] as String?;
                    final isChatbot = data['isChatbot'] == true;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.teal),
                        title: Row(
                          children: [
                            Expanded(child: Text(data['name'] ?? 'Không rõ')),
                            if (isChatbot)
                              const Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: Text(
                                  '(Chatbot)',
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Triệu chứng: ${data['symptom'] ?? 'Không có'}'),
                            Text('Ngày yêu cầu: $formattedDate'),
                            Text(
                              'Trạng thái: ${status == 'pending' ? 'Chờ xử lý' : status == 'responded' ? 'Đã phản hồi' : 'Hoàn thành'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: status == 'pending'
                                    ? Colors.orange
                                    : status == 'responded'
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ),
                            if (doctorResponse != null && doctorResponse.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  isChatbot
                                      ? 'Phản hồi từ Chatbot: $doctorResponse'
                                      : 'Phản hồi từ bác sĩ: $doctorResponse',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status == 'responded')
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _markAsCompleted(documentId),
                                tooltip: 'Đánh dấu hoàn thành',
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRequest(documentId),
                              tooltip: 'Xóa yêu cầu',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symptomController.dispose();
    super.dispose();
  }
}