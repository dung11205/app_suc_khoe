import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_apps/profile_screen/edit_personal_info_screen.dart';
import 'package:intl/intl.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    final avatarBase64 = _userData?['avatar'];
    ImageProvider? avatarImage;
    if (avatarBase64 != null && avatarBase64 is String && avatarBase64.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(avatarBase64));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ sức khỏe'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
              );
              if (result == true) {
                setState(() => _isLoading = true);
                await _fetchUserData();
              }
            },
            tooltip: 'Chỉnh sửa thông tin cá nhân',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? const Icon(Icons.person, size: 40, color: Colors.blueAccent)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin cá nhân',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Họ và tên', _userData?['name'] ?? 'Chưa cập nhật'),
                                _buildInfoRow('Tuổi', _userData?['age']?.toString() ?? 'Chưa cập nhật'),
                                _buildInfoRow('Giới tính', _userData?['gender'] ?? 'Chưa cập nhật'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  HealthFormWidget(userId: user.uid),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lịch sử sức khỏe',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('health_records')
                                .where('userId', isEqualTo: user.uid)
                                .orderBy('date', descending: true)
                                .limit(5)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Text('Chưa có bản ghi sức khỏe');
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final record = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                                  final date = (record['date'] as Timestamp).toDate();
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title: Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}'),
                                      subtitle: Text(
                                        'Chiều cao: ${record['height']?.toString() ?? 'Chưa có'} cm\n'
                                        'Cân nặng: ${record['weight']?.toString() ?? 'Chưa có'} kg\n'
                                        'Huyết áp: ${record['blood_pressure'] ?? 'Chưa có'}\n'
                                        'Đường huyết: ${record['blood_glucose']?.toString() ?? 'Chưa có'} mg/dL\n'
                                        'Nhịp tim: ${record['heart_rate']?.toString() ?? 'Chưa có'} lần/phút\n'
                                        'Tình trạng: ${record['symptoms'] ?? 'Không có'}',
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
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class HealthFormWidget extends StatefulWidget {
  final String userId;
  const HealthFormWidget({super.key, required this.userId});

  @override
  State<HealthFormWidget> createState() => _HealthFormWidgetState();
}

class _HealthFormWidgetState extends State<HealthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bpController = TextEditingController();
  final _bloodGlucoseController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _symptomsController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveHealthRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userId == null || FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Refresh authentication token
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      final bloodGlucose = double.tryParse(_bloodGlucoseController.text);
      final heartRate = int.tryParse(_heartRateController.text);

      if (height == null || weight == null || bloodGlucose == null || heartRate == null) {
        throw Exception('Dữ liệu nhập không hợp lệ');
      }

      final record = {
        'date': Timestamp.now(),
        'height': height,
        'weight': weight,
        'blood_pressure': _bpController.text.trim(),
        'blood_glucose': bloodGlucose,
        'heart_rate': heartRate,
        'symptoms': _symptomsController.text.trim(),
        'userId': widget.userId, // Added userId field
      };

      print('Saving health record: $record');

      await FirebaseFirestore.instance
          .collection('health_records')
          .add(record);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ thành công'), backgroundColor: Colors.green),
      );

      // Clear the form after saving
      _heightController.clear();
      _weightController.clear();
      _bpController.clear();
      _bloodGlucoseController.clear();
      _heartRateController.clear();
      _symptomsController.clear();

    } catch (e) {
      print('Error saving health record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không thể lưu hồ sơ, vui lòng kiểm tra dữ liệu nhập'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(labelText: 'Chiều cao (cm)'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value!.isEmpty) return 'Vui lòng nhập chiều cao';
              final height = double.tryParse(value);
              if (height == null || height <= 0) return 'Chiều cao phải lớn hơn 0';
              return null;
            },
          ),
          TextFormField(
            controller: _weightController
,
decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
keyboardType: TextInputType.number,
validator: (value) {
if (value!.isEmpty) return 'Vui lòng nhập cân nặng';
final weight = double.tryParse(value);
if (weight == null || weight <= 0) return 'Cân nặng phải lớn hơn 0';
return null;
},
),
TextFormField(
controller: _bpController,
decoration: const InputDecoration(labelText: 'Huyết áp'),
),
TextFormField(
controller: _bloodGlucoseController,
decoration: const InputDecoration(labelText: 'Đường huyết (mg/dL)'),
keyboardType: TextInputType.number,
validator: (value) {
if (value!.isEmpty) return 'Vui lòng nhập đường huyết';
final glucose = double.tryParse(value);
if (glucose == null || glucose <= 0) return 'Đường huyết phải lớn hơn 0';
return null;
},
),
TextFormField(
controller: _heartRateController,
decoration: const InputDecoration(labelText: 'Nhịp tim (lần/phút)'),
keyboardType: TextInputType.number,
validator: (value) {
if (value!.isEmpty) return 'Vui lòng nhập nhịp tim';
final heartRate = int.tryParse(value);
if (heartRate == null || heartRate <= 0) return 'Nhịp tim phải lớn hơn 0';
return null;
},
),
TextFormField(
controller: _symptomsController,
decoration: const InputDecoration(labelText: 'Triệu chứng'),
),
const SizedBox(height: 16),
_isSaving
? const CircularProgressIndicator()
: ElevatedButton(
onPressed: _saveHealthRecord,
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
backgroundColor: Colors.blueAccent,
foregroundColor: Colors.white,
),
child: const Text('Lưu hồ sơ', style: TextStyle(fontSize: 16)),
),
],
),
);
}
}