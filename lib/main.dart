import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 👈 Thêm dòng này
import 'firebase_options.dart';

import 'package:health_apps/screens/login_screen.dart' as login;
import 'package:health_apps/screens/register_screen.dart' as register;
import 'package:health_apps/screens/home_screen.dart';
import 'package:health_apps/screens/main_screen.dart';
import 'package:health_apps/screens/notification_screen.dart';
import 'package:health_apps/screens/profile_screen.dart';
import 'screens/edit_personal_info_screen.dart';
import 'screens/family_members_screen.dart';
import 'screens/visited_places_screen.dart';
import 'screens/appointment_history_screen.dart';
import 'screens/vaccine_passport_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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

      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', ''), // Tiếng Việt
        Locale('en', ''), // Tiếng Anh
      ],

      initialRoute: '/login',
      routes: {
        '/login': (context) => const login.LoginScreen(),
        '/register': (context) => const register.RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const HomeScreen(),
        '/notification': (context) => const NotificationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-personal': (context) => const EditPersonalInfoScreen(),
        '/family-members': (context) => const FamilyMembersScreen(),
        '/visited-places': (context) => const VisitedPlacesScreen(),
        '/appointment-history': (context) => const AppointmentHistoryScreen(),
        '/vaccine-passport': (context) => const VaccinePassportScreen(),
      },
      home: const login.LoginScreen(),
    );
  }
}
