import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'providers/app_settings_provider.dart';
import 'screens/login_screen.dart' as login;
import 'screens/register_screen.dart' as register;
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';
import 'profile_screen/edit_personal_info_screen.dart';
import 'profile_screen/family_members_screen.dart';
import 'profile_screen/visited_places_screen.dart';
import 'profile_screen/appointment_history_screen.dart';
import 'profile_screen/vaccine_passport_screen.dart';
import 'profile_screen/setting.dart';
import 'home_screen/appointment_booking_screen.dart';
import 'home_screen/covid_certificate_screen.dart';
import 'home_screen/f0_consultation_screen.dart';
import 'home_screen/feedback_screen.dart';
import 'home_screen/health_profile_screen.dart';
import 'home_screen/medical_declaration_screen.dart';
import 'home_screen/more_screen.dart';
import 'home_screen/remote_consulting_screen.dart';
import 'home_screen/vaccine_registration_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Background] ${message.notification?.title}: ${message.notification?.body}');
}

Future<void> _setupFlutterNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      if (details.payload != null) {
        navigatorKey.currentState?.pushNamed('/notification');
      }
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'default_channel',
      'Thông báo chung',
      channelDescription: 'Kênh thông báo mặc định',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: '/notification',
    );
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final settings = AppSettingsProvider();
  await settings.loadSettings();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupFlutterNotifications();

  final fcm = FirebaseMessaging.instance;
  final token = await fcm.getToken();
  if (token != null) {
    debugPrint('FCM Token: $token');
  } else {
    debugPrint('Không thể lấy token FCM');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Health Tracking App',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/main',
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
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
            '/appointment-booking': (context) => AppointmentBookingScreen(),
            '/health-profile': (context) => const HealthProfileScreen(),
            '/vaccine-feedback': (context) => const VaccineFeedbackScreen(),
            '/remote-consulting': (context) => const RemoteConsultingScreen(),
            '/more': (context) => const MoreScreen(),
            '/setting': (context) => const SettingScreen(),
          },
        );
      },
    );
  }
}
