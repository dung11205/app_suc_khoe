import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CovidCertificateScreen extends StatefulWidget {
  const CovidCertificateScreen({Key? key}) : super(key: key);

  @override
  State<CovidCertificateScreen> createState() => _CovidCertificateScreenState();
}

class _CovidCertificateScreenState extends State<CovidCertificateScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _dosesController = TextEditingController();
  final TextEditingController _vaccineNameController = TextEditingController();

  Map<String, dynamic>? userData;
  Map<String, dynamic>? certificateData;
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  List<DateTime> _vaccinationDates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final certDoc = await _firestore.collection('covid_certificates').doc(user.uid).get();
      userData = userDoc.data();
      certificateData = certDoc.data();

      // Parse dates
      if (certificateData != null && certificateData!['vaccinationDates'] != null) {
        _vaccinationDates = (certificateData!['vaccinationDates'] as List)
            .where((e) => e != 'Chưa tiêm')
            .map((e) => _dateFormat.parse(e))
            .toList();
      }

      _dosesController.text = certificateData?['doses']?.toString() ?? '';
      _vaccineNameController.text = certificateData?['vaccineName'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addVaccinationDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _vaccinationDates.add(picked));
    }
  }

  Future<void> _updateData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final vaccinationDates = _vaccinationDates.map((e) => _dateFormat.format(e)).toList();
      await _firestore.collection('covid_certificates').doc(user.uid).set({
        'doses': int.tryParse(_dosesController.text) ?? 0,
        'vaccinationDates': vaccinationDates.isNotEmpty ? vaccinationDates : ['Chưa tiêm'],
        'vaccineName': _vaccineNameController.text,
      });
      Navigator.of(context).pop();
      _loadData();
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật chứng nhận Covid'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_dosesController, 'Số liều đã tiêm', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ngày tiêm:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _addVaccinationDate(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _vaccinationDates.map((date) {
                    return Chip(
                      label: Text(_dateFormat.format(date)),
                      onDeleted: () => setState(() => _vaccinationDates.remove(date)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _buildTextField(_vaccineNameController, 'Tên vaccine'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _updateData,
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chứng nhận ngừa Covid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showUpdateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin người dùng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Họ và tên'),
                        subtitle: Text(userData?['name'] ?? 'Chưa có tên'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cake),
                        title: const Text('Ngày sinh'),
                        subtitle: Text(userData?['dob'] ?? 'Chưa có ngày sinh'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('Tuổi'),
                        subtitle: Text('${userData?['age'] ?? 0}'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Thông tin chứng nhận Covid',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.vaccines),
                        title: const Text('Số liều đã tiêm'),
                        subtitle: Text('${certificateData?['doses'] ?? 0}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: const Text('Ngày tiêm'),
                        subtitle: Text(
                          (certificateData?['vaccinationDates'] as List?)?.join(', ') ?? 'Chưa tiêm',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.medical_services),
                        title: const Text('Tên vaccine'),
                        subtitle: Text('${certificateData?['vaccineName'] ?? 'Chưa có'}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
