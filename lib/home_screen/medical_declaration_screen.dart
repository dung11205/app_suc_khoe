// medical_declaration_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalDeclarationScreen extends StatefulWidget {
  const MedicalDeclarationScreen({super.key});

  @override
  _MedicalDeclarationScreenState createState() => _MedicalDeclarationScreenState();
}

class _MedicalDeclarationScreenState extends State<MedicalDeclarationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _symptomsController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingData = true;
  bool _isSubmitted = false;
  String? _contactHistoryValue = 'Không';

  @override
  void initState() {
    super.initState();
    _loadLatestDeclaration();
  }

  Future<void> _loadLatestDeclaration() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isFetchingData = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('medical_declarations')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _symptomsController.text = data['symptoms'] ?? '';
      _contactHistoryValue = data['contact_history'] ?? 'Không';
      _isSubmitted = true;
    }

    setState(() => _isFetchingData = false);
  }

  Future<void> _submitDeclaration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('Người dùng chưa đăng nhập');

        await FirebaseFirestore.instance.collection('medical_declarations').add({
          'userId': userId,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'symptoms': _symptomsController.text,
          'contact_history': _contactHistoryValue,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() => _isSubmitted = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Khai báo thành công!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _enableFormForUpdate() {
    setState(() {
      _isSubmitted = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khai Báo Y Tế'),
        backgroundColor: const Color(0xFF4FC1FF),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userId == null
          ? _buildLoginPrompt()
          : _isFetchingData
              ? const Center(child: CircularProgressIndicator(color: Colors.grey))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin khai báo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Họ và tên',
                    icon: Icons.person,
                    enabled: !_isSubmitted,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    enabled: !_isSubmitted,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _symptomsController,
                    label: 'Triệu chứng (nếu có)',
                    icon: Icons.medical_services,
                    maxLines: 1,
                    enabled: !_isSubmitted,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _contactHistoryValue,
                    onChanged: _isSubmitted
                        ? null
                        : (String? newValue) {
                            setState(() {
                              _contactHistoryValue = newValue;
                            });
                          },
                    items: <String>['Có', 'Không']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Lịch sử tiếp xúc (nếu có)',
                      prefixIcon: Icon(Icons.history, color: Colors.grey[600]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.grey))
                      : _isSubmitted
                          ? Column(
                              children: [
                                Center(
                                  child: Text(
                                    ' Bạn đã khai báo y tế.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF4FC1FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: _enableFormForUpdate,
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    label: const Text(
                                      'Cập nhật lại',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: ElevatedButton.icon(
                                onPressed: _submitDeclaration,
                                icon: Icon(Icons.send, color: Colors.grey[600]),
                                label: const Text(
                                  'Gửi khai báo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 38, 169, 240),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 40, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng đăng nhập để sử dụng tính năng này.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Đăng nhập', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
