import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:health_apps/home_screen/appointment_booking_screen.dart';
import 'package:health_apps/home_screen/covid_certificate_screen.dart';
import 'package:health_apps/home_screen/f0_consultation_screen.dart';
import 'package:health_apps/home_screen/health_profile_screen.dart';
import 'package:health_apps/home_screen/medical_declaration_screen.dart';
import 'package:health_apps/home_screen/more_screen.dart';
import 'package:health_apps/home_screen/vaccine_feedback_screen.dart';
import 'package:health_apps/home_screen/vaccine_registration_screen.dart';
import 'firebase_options.dart';
import 'package:health_apps/screens/login_screen.dart' as login;
import 'package:health_apps/screens/register_screen.dart' as register;
import 'package:health_apps/screens/home_screen.dart';
import 'package:health_apps/screens/main_screen.dart';
import 'package:health_apps/screens/notification_screen.dart';
import 'package:health_apps/screens/profile_screen.dart';
import 'profile_screen/edit_personal_info_screen.dart';
import 'profile_screen/family_members_screen.dart';
import 'profile_screen/visited_places_screen.dart';
import 'profile_screen/appointment_history_screen.dart';
import 'profile_screen/vaccine_passport_screen.dart';

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
        fontFamily: 'Inter', // Thêm font Inter vào ThemeData
        fontFamilyFallback: const ['Roboto', 'sans-serif'], // Font dự phòng
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
        '/appointment-history': (context) => AppointmentHistoryScreen(),
        '/vaccine-passport': (context) => const VaccinePassportScreen(),
        '/medical-declaration': (context) => const MedicalDeclarationScreen(),
        '/covid-certificate': (context) => const CovidCertificateScreen(),
        '/f0-consultation': (context) => const F0ConsultationScreen(),
        '/vaccine-registration': (context) => const VaccineRegistrationScreen(),
        '/appointment-booking': (context) => const AppointmentBookingScreen(),
        '/health-profile': (context) => const HealthProfileScreen(),
        '/vaccine-feedback': (context) => const VaccineFeedbackScreen(),
        '/more': (context) => const MoreScreen(),
      },
      home: const login.LoginScreen(),
    );
  }
}