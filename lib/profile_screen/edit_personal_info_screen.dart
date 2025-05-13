import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart'; // Import UserService

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final UserService _userService = UserService(); // Khởi tạo UserService
  String? _selectedGender;
  bool _isSaving = false;
  File? _avatarFile;
  String? _avatarBase64;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getUserData();
      if (userData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục')),
          );
        }
        return;
      }

      setState(() {
        _nameController.text = userData['name'] ?? '';
        _dobController.text = userData['dob'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _idController.text = userData['id'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _originalEmail = _emailController.text;
        _selectedGender = userData['gender'];
        _avatarBase64 = userData['avatar'];
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxHeight: 512,
        maxWidth: 512,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);

        if (base64String.length > 1 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ảnh quá lớn, vui lòng chọn ảnh nhỏ hơn 1MB')),
            );
          }
          return;
        }

        setState(() {
          _avatarFile = File(picked.path);
          _avatarBase64 = base64String;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }

  void _updateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    _ageController.text = age.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
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
          _dobController.text = _dateFormat.format(picked);
          _updateAge(picked);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ngày sinh: $e')),
        );
      }
    }
  }

  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để lưu thông tin')),
        );
      }
      return;
    }

    final newEmail = _emailController.text.trim();

    try {
      if (newEmail != _originalEmail) {
        // Gửi email xác minh cho email mới
        await user.verifyBeforeUpdateEmail(newEmail);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng kiểm tra email mới để xác minh trước khi lưu.'),
            ),
          );
        }
        setState(() => _isSaving = false);
        return; // Chờ người dùng xác minh email trước khi lưu toàn bộ thông tin
      }

      // Dữ liệu cần lưu
      final userData = {
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'phone': _phoneController.text.trim(),
        'id': _idController.text.trim(),
        'email': newEmail,
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'avatar': _avatarBase64,
      };

      // Sử dụng UserService để lưu thông tin vào Firestore
      await _userService.updateUserData(user.uid, userData);

      // Cập nhật displayName trong Firebase Auth
      await user.updateDisplayName(_nameController.text.trim());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thông tin cá nhân thành công')),
        );
        Navigator.pop(context, true); // Trả về true để báo hiệu lưu thành công
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
    ImageProvider? avatarImage;
    if (_avatarFile != null) {
      avatarImage = FileImage(_avatarFile!);
    } else if (_avatarBase64 != null) {
      try {
        avatarImage = MemoryImage(base64Decode(_avatarBase64!));
      } catch (e) {
        avatarImage = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin cá nhân'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.blueAccent)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(_nameController, 'Họ và tên', validator: _validateName),
              const SizedBox(height: 12),
              _buildTextFormField(
                _dobController,
                'Ngày sinh',
                readOnly: true,
                suffixIcon: Icons.calendar_today,
                onTap: () => _selectDate(context),
                validator: _validateDob,
              ),
              const SizedBox(height: 12),
              _buildTextFormField(
                _ageController,
                'Tuổi',
                readOnly: true,
                keyboardType: TextInputType.number,
                validator: _validateAge,
              ),
              const SizedBox(height: 12),
              _buildGenderDropdown(),
              const SizedBox(height: 12),
              _buildTextFormField(
                _phoneController,
                'Số điện thoại',
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              _buildTextFormField(_idController, 'Số CCCD/Hộ chiếu', validator: _validateId),
              const SizedBox(height: 12),
              _buildTextFormField(
                _emailController,
                'Email (Gmail)',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveUserInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Lưu thông tin', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập họ và tên';
    if (value.trim().length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
    return null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng chọn ngày sinh';
    try {
      _dateFormat.parseStrict(value);
      return null;
    } catch (e) {
      return 'Định dạng ngày sinh không hợp lệ';
    }
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng chọn ngày sinh để tính tuổi';
    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Tuổi không hợp lệ';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Số điện thoại phải có 10 chữ số';
    return null;
  }

  String? _validateId(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số CCCD/Hộ chiếu';
    if (!RegExp(r'^\d{9,12}$').hasMatch(value)) return 'Số CCCD/Hộ chiếu không hợp lệ';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email không hợp lệ';
    if (!value.endsWith('@gmail.com')) return 'Vui lòng sử dụng email Gmail';
    return null;
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    IconData? suffixIcon,
    Function()? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      ),
      onTap: onTap,
      validator: validator ?? (value) => value == null || value.isEmpty ? 'Vui lòng nhập $label' : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['Nam', 'Nữ', 'Khác']
          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
          .toList(),
      onChanged: (value) => setState(() => _selectedGender = value),
      validator: (value) => value == null ? 'Vui lòng chọn giới tính' : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}