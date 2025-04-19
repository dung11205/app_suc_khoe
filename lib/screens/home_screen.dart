import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? 'Người dùng');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xin chào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Các nút chức năng lớn
          Row(
            children: [
              _buildMainFeatureCard(
                FontAwesomeIcons.fileMedical,
                'Khai báo\nY tế',
                Colors.blue,
              ),
              _buildMainFeatureCard(
                FontAwesomeIcons.syringe,
                'Chứng nhận\nngừa Covid',
                Colors.green,
              ),
              _buildMainFeatureCard(
                FontAwesomeIcons.userDoctor,
                'Tư vấn\nsức khoẻ F0',
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grid chức năng phụ
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureIcon(FontAwesomeIcons.passport, 'Hộ chiếu\nvắc-xin'),
              _buildFeatureIcon(FontAwesomeIcons.notesMedical, 'Đăng ký\ntiêm chủng'),
              _buildFeatureIcon(Icons.calendar_today, 'Đặt hẹn\nkhám'),
              _buildFeatureIcon(Icons.folder_shared, 'Hồ sơ\nsức khỏe'),
              _buildFeatureIcon(Icons.report_problem, 'Phản ánh\ntiêm chủng'),
              _buildFeatureIcon(Icons.more_horiz, 'Xem thêm'),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Cẩm nang y tế',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📚 Nội dung cẩm nang (tạm placeholder)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget cho 3 nút chức năng lớn
  Widget _buildMainFeatureCard(IconData icon, String title, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho icon chức năng phụ
  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: FaIcon(icon, size: 24, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
