import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_apps/profile_screen/edit_personal_info_screen.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';

class VaccineRegistrationScreen extends StatefulWidget {
  const VaccineRegistrationScreen({super.key});

  @override
  State<VaccineRegistrationScreen> createState() => _VaccineRegistrationScreenState();
}

class _VaccineRegistrationScreenState extends State<VaccineRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _healthConditionController = TextEditingController();
  final _desiredDateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final UserService _userService = UserService();
  String? _vaccineType, _dose, _location;
  bool _isSaving = false;
  bool _isProfileComplete = false;
  List<Map<String, dynamic>> _registrations = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserRegistrations();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục')),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      final userData = await _userService.getUserData();
      if (userData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải thông tin người dùng')),
          );
        }
        return;
      }

      setState(() {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _dobController.text = userData['dob'] ?? '';
        _isProfileComplete = _nameController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _dobController.text.isNotEmpty;
      });

      if (!_isProfileComplete && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng cập nhật hồ sơ cá nhân trước khi đăng ký'),
            action: SnackBarAction(
              label: 'Cập nhật',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                );
                if (result == true) {
                  await _loadUserData();
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _fetchUserRegistrations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vaccine_registrations')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _registrations = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải lịch sử đăng ký: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        locale: const Locale('vi', 'VN'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blueAccent,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && context.mounted) {
        setState(() {
          _desiredDateController.text = _dateFormat.format(picked);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ngày: $e')),
        );
      }
    }
  }

  Future<void> _saveRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isProfileComplete) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng hoàn thiện hồ sơ cá nhân trước')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('vaccine_registrations').add({
        'userId': user!.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'vaccineType': _vaccineType,
        'dose': _dose,
        'desiredDate': _desiredDateController.text.trim(),
        'location': _location,
        'healthCondition': _healthConditionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký tiêm chủng thành công')),
        );
        await _fetchUserRegistrations(); // Refresh the registration list
        setState(() {
          _vaccineType = null;
          _dose = null;
          _location = null;
          _desiredDateController.clear();
          _healthConditionController.clear();
        });
        _formKey.currentState!.reset(); // Reset form validation
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu thông tin: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tiêm chủng'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ScrollConfiguration(
        behavior: NoScrollbarBehavior(), // ← Thêm dòng này
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFormField(
                      _nameController,
                      'Họ và tên',
                      readOnly: true,
                      validator: (value) => value!.isEmpty ? 'Vui lòng cập nhật họ và tên' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextFormField(
                      _dobController,
                      'Ngày sinh',
                      readOnly: true,
                      validator: (value) => value!.isEmpty ? 'Vui lòng cập nhật ngày sinh' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextFormField(
                      _phoneController,
                      'Số điện thoại',
                      readOnly: true,
                      validator: (value) => value!.isEmpty ? 'Vui lòng cập nhật số điện thoại' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      'Loại vắc-xin',
                      _vaccineType,
                      ['COVID-19', 'Cúm', 'Sởi', 'HPV'],
                      (value) => setState(() => _vaccineType = value),
                      validator: (value) => value == null ? 'Vui lòng chọn loại vắc-xin' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      'Liều tiêm',
                      _dose,
                      ['Liều 1', 'Liều 2', 'Mũi nhắc lại'],
                      (value) => setState(() => _dose = value),
                      validator: (value) => value == null ? 'Vui lòng chọn liều tiêm' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextFormField(
                      _desiredDateController,
                      'Ngày mong muốn',
                      readOnly: true,
                      suffixIcon: Icons.calendar_today,
                      onTap: () => _selectDate(context),
                      validator: (value) => value!.isEmpty ? 'Vui lòng chọn ngày' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      'Địa điểm tiêm',
                      _location,
                      ['Bệnh viện Bạch Mai', 'Trung tâm Y tế Hoàn Kiếm', 'Bệnh viện Việt Đức'],
                      (value) => setState(() => _location = value),
                      validator: (value) => value == null ? 'Vui lòng chọn địa điểm' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextFormField(
                      _healthConditionController,
                      'Tình trạng sức khỏe (nếu có)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Đăng ký', style: TextStyle(fontSize: 16)),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lịch sử đăng ký',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _registrations.isEmpty
                  ? const Center(child: Text('Chưa có đăng ký nào.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _registrations.length,
                      itemBuilder: (context, index) {
                        final data = _registrations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('${data['vaccineType']} - ${data['dose']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày mong muốn: ${data['desiredDate']}'),
                                Text('Địa điểm: ${data['location']}'),
                                if (data['healthCondition'] != null && data['healthCondition'].toString().isNotEmpty)
                                  Text('Ghi chú: ${data['healthCondition']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    IconData? suffixIcon,
    Function()? onTap,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      ),
      onTap: onTap,
      validator: validator ?? (value) => null,
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// Thêm lớp này vào cuối file hoặc tách riêng nếu bạn dùng lại
class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // không hiện scrollbar
  }
}
