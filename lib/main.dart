import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat/firebase_options.dart';
import 'package:chat/core/theme/app_theme.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:chat/bindings/initial_binding.dart';
import 'package:chat/views/onboarding/onboarding_screen.dart';
import 'package:chat/views/main/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed/skipped: $e");
  }

  try {
    await Supabase.initialize(
      url: 'https://ppgrrdbdvncnhnnlkbfw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwZ3JyZGJkdm5jbmhubmxrYmZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3ODYyNjksImV4cCI6MjA5NTM2MjI2OX0.vSYD7yUawRNBefDXEtl4HjU2QiJe3EdDQ20gdNYfbbM',
    );
    debugPrint("Supabase initialized successfully! 🚀");
  } catch (e) {
    debugPrint("Supabase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Premium Chat App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default, dynamic changes are managed by ThemeController and Get.changeThemeMode
      initialBinding: InitialBinding(),
      
      // Unified routing engine managed reactively in AuthController
      home: const InitializingScreen(),
    );
  }
}

// Gorgeous initial loading splash screen
class InitializingScreen extends StatelessWidget {
  const InitializingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background blobs
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.12),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rotating / breathing logo card
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 36),
              
              // App Name
              Text(
                "PREMIUM CHAT",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                "Securely Connecting Lives",
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Elegant material loader
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
