import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:health_apps/screens/login_screen.dart' as login;
import 'package:health_apps/screens/register_screen.dart' as register;
import 'package:health_apps/screens/home_screen.dart';
import 'package:health_apps/screens/main_screen.dart';
import 'package:health_apps/screens/notification_screen.dart';
import 'package:health_apps/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Đảm bảo đăng xuất khi khởi động ứng dụng
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    print('Lỗi khởi tạo Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Đảm bảo khởi động từ màn hình đăng nhập
      routes: {
        '/login': (context) => const login.LoginScreen(),
        '/register': (context) => const register.RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const HomeScreen(),
        '/notification': (context) => const NotificationScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      home: const login.LoginScreen(), // Bỏ StreamBuilder tạm thời để kiểm tra
    );
  }
}