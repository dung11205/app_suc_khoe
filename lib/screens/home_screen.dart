import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/responsive_layout.dart';

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
    final name = _name ?? user?.displayName ?? user?.email ?? 'Người dùng';

    ImageProvider? avatarImage;
    if (_avatarBase64 != null) {
      try {
        avatarImage = MemoryImage(base64Decode(_avatarBase64!));
      } catch (e) {
        avatarImage = null;
      }
    }

    return ResponsiveLayout(
      mobile: _buildMainContent(context, name, avatarImage, maxIconsPerRow: 3),
      tablet: _buildMainContent(context, name, avatarImage, maxIconsPerRow: 4),
      desktop: _buildMainContent(context, name, avatarImage, maxIconsPerRow: 6),
    );
  }

  Widget _buildMainContent(BuildContext context, String name, ImageProvider? avatarImage,
      {required int maxIconsPerRow}) {
    final double iconWidth = MediaQuery.of(context).size.width / maxIconsPerRow - 32;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: avatarImage,
                    child: avatarImage == null ? const Icon(Icons.person, color: Colors.white) : null,
                    backgroundColor: Colors.blueAccent,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Xin chào', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMainButton(
                  icon: FontAwesomeIcons.fileMedical,
                  label: 'Khai báo\nY tế',
                  color: Colors.blueAccent,
                  routeName: '/medical-declaration',
                ),
                _buildMainButton(
                  icon: FontAwesomeIcons.syringe,
                  label: 'Chứng nhận\nngừa Covid',
                  color: Colors.green,
                  routeName: '/covid-certificate',
                ),
                _buildMainButton(
                  icon: FontAwesomeIcons.userDoctor,
                  label: 'Tư vấn\nsức khoẻ F0',
                  color: Colors.redAccent,
                  routeName: '/f0-consultation',
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSubIcon(FontAwesomeIcons.passport, 'Phản ứng\nsau tiêm', '/vaccine-feedback', iconWidth),
                  _buildSubIcon(FontAwesomeIcons.notesMedical, 'Đăng ký\ntiêm chủng', '/vaccine-registration', iconWidth),
                  _buildSubIcon(Icons.calendar_today, 'Đặt hẹn\nkhám', '/appointment-booking', iconWidth),
                  _buildSubIcon(Icons.folder_shared, 'Hồ sơ\nsức khỏe', '/health-profile', iconWidth),
                  _buildSubIcon(Icons.support_agent, 'Tư vấn\ntừ xa', '/remote-consulting', iconWidth),
                  _buildSubIcon(Icons.more_horiz, 'Xem thêm', '/more', iconWidth),
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
      ),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required Color color,
    required String routeName,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, routeName),
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
      ),
    );
  }

  Widget _buildSubIcon(IconData icon, String label, String routeName, double width) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: SizedBox(
        width: width,
        child: Column(
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
        ),
      ),
    );
  }
}
