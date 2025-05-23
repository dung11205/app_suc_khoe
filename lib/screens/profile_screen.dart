import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../profile_screen/setting.dart'; // <-- import SettingScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarBase64;
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();

        setState(() {
          _avatarBase64 = data?['avatar'];
          _name = data?['name'] ?? user.displayName ?? 'Tên người dùng';
        });
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final email = user.email ?? 'Không có email';
    ImageProvider? avatarImage;
    if (_avatarBase64 != null) {
      try {
        avatarImage = MemoryImage(base64Decode(_avatarBase64!));
      } catch (e) {
        avatarImage = null;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, size: 35, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name ?? 'Tên người dùng',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (_) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // Menu
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                itemCount: _menuItems.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return ListTile(
                    leading: Icon(item.icon, color: Colors.grey[700]),
                    title: Text(item.title),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      switch (item.title) {
                        case 'Thông tin cá nhân':
                          Navigator.pushNamed(context, '/edit-personal');
                          break;
                        case 'Thành viên gia đình':
                          Navigator.pushNamed(context, '/family-members');
                          break;
                        case 'Nơi đã đến':
                          Navigator.pushNamed(context, '/visited-places');
                          break;
                        case 'Lịch sử đặt khám':
                          Navigator.pushNamed(context, '/appointment-history');
                          break;
                        case 'Hộ chiếu vắc-xin':
                          Navigator.pushNamed(context, '/vaccine-passport');
                          break;
                        case 'Giới thiệu':
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Chức năng Giới thiệu chưa được triển khai'),
                            ),
                          );
                          break;
                        case 'Cài đặt':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingScreen(),
                            ),
                          );
                          break;
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;

  _MenuItem(this.icon, this.title);
}

final List<_MenuItem> _menuItems = [
  _MenuItem(Icons.person, 'Thông tin cá nhân'),
  _MenuItem(Icons.group, 'Thành viên gia đình'),
  _MenuItem(Icons.location_on, 'Nơi đã đến'),
  _MenuItem(Icons.history, 'Lịch sử đặt khám'),
  _MenuItem(Icons.vaccines, 'Hộ chiếu vắc-xin'),
  _MenuItem(Icons.info_outline, 'Giới thiệu'),
  _MenuItem(Icons.settings, 'Cài đặt'),
];
