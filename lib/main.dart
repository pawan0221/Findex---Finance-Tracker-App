import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';
import 'pages/onboarding_page.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/account_page.dart';
import 'pages/reports_page.dart';
import 'pages/upi_qr_page.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FindexApp());
}

class FindexApp extends StatelessWidget {
  const FindexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Findex',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        initialRoute: '/splash',
        routes: {
          '/splash':       (_) => const SplashScreen(),
          '/onboarding':   (_) => const OnboardingPage(),
          '/':             (_) => const WelcomePage(),
          '/login':        (_) => const LoginPage(),
          '/phone-login':  (_) => const PhoneLoginPage(),
          '/signup':       (_) => const SignupPage(),
          '/dashboard':    (_) => const DashboardPage(),
          '/account':      (_) => const AccountPage(),
          '/reports':      (_) => const ReportsPage(),
          '/upi-qr':       (_) => const UpiQrPage(),
        },
      ),
    );
  }

  ThemeData _darkTheme() => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F1628),
    colorScheme: const ColorScheme.dark(primary: Color(0xFF8B6AFF), secondary: Color(0xFF64B5F6)),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F1628), elevation: 0, centerTitle: true),
    cardColor: const Color(0xFF1C2235),
  );

  ThemeData _lightTheme() => ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF0F2F8),
    colorScheme: const ColorScheme.light(primary: Color(0xFF8B6AFF), secondary: Color(0xFF64B5F6)),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF0F2F8), elevation: 0, centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F1628))),
    cardColor: Colors.white,
  );
}