import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'screens/home_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/aspiration_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/announcement_screen.dart';
import 'screens/member_directory_screen.dart';
import 'screens/inventory_screen.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/organization_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await AuthService.instance.init();
  await DataService.instance.init();
  await OrganizationService.instance.init();
  runApp(const OrganiSyncApp());
}

class OrganiSyncApp extends StatelessWidget {
  const OrganiSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrganiSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3CBC),
          primary: const Color(0xFF6C3CBC),
          secondary: const Color(0xFF9B59B6),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => AuthService.instance.isLoggedIn
            ? const MainNavigation()
            : const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/announcements': (context) => const AnnouncementScreen(),
        '/members': (context) => const MemberDirectoryScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/main': (context) => AuthService.instance.isLoggedIn
            ? const MainNavigation()
            : const LoginScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthService.instance.isLoggedIn
        ? const MainNavigation()
        : const LoginScreen();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onMenuTap(int index) {
    setState(() => _currentIndex = index);
  }

  late final List<Widget> _screens = [
    HomeScreen(onMenuTap: _onMenuTap),
    const FinanceScreen(),
    const ScheduleScreen(),
    const ActivityScreen(),
    const AspirationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color(0xFF6C3CBC),
        buttonBackgroundColor: const Color(0xFF9B59B6),
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          Icon(Icons.home_rounded, color: Colors.white, size: 28),
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
          Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
          Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
          Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}