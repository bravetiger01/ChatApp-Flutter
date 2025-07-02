// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screens.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screens.dart';
import 'screens/profile_screens.dart';
import 'screens/new_chat_screen.dart';
import 'screens/new_contact_screen.dart';
import 'screens/your_profile_screen.dart';
import 'screens/call_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const SamParkApp());
}

class SamParkApp extends StatelessWidget {
  const SamParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'SamPark',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/new-chat': (context) => const NewChatScreen(),
        '/new-contact': (context) => const NewContactScreen(),
        '/your-profile': (context) => const YourProfileScreen(),
        '/call': (context) => const CallScreen(),
      },
    );
  }
}