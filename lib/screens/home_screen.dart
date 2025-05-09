import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _name;
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      setState(() {
        _name = data?['name'] ?? user.displayName ?? user.email ?? 'Người dùng';
        _avatarBase64 = data?['avatar'];
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = _name ??
        (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : (user?.email ?? 'Người dùng'));

    ImageProvider? avatarImage;
    if (_avatarBase64 != null) {
      try {
        avatarImage = MemoryImage(base64Decode(_avatarBase64!));
      } catch (e) {
        avatarImage = null;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: Colors.blueAccent,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3 nút chính
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMainButton(
                icon: FontAwesomeIcons.fileMedical,
                label: 'Khai báo\nY tế',
                color: Colors.blueAccent,
              ),
              _buildMainButton(
                icon: FontAwesomeIcons.syringe,
                label: 'Chứng nhận\nngừa Covid',
                color: Colors.green,
              ),
              _buildMainButton(
                icon: FontAwesomeIcons.userDoctor,
                label: 'Tư vấn\nsức khoẻ F0',
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Grid icon phụ
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSubIcon(FontAwesomeIcons.passport, 'Hộ chiếu\nvắc-xin'),
                _buildSubIcon(FontAwesomeIcons.notesMedical, 'Đăng ký\ntiêm chủng'),
                _buildSubIcon(Icons.calendar_today, 'Đặt hẹn\nkhám'),
                _buildSubIcon(Icons.folder_shared, 'Hồ sơ\nsức khỏe'),
                _buildSubIcon(Icons.report_problem, 'Phản ánh\ntiêm chủng'),
                _buildSubIcon(Icons.more_horiz, 'Xem thêm'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Cẩm nang y tế',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.menu_book, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📚 Nội dung cẩm nang (tạm placeholder)',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade50,
          child: FaIcon(icon, size: 26, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}