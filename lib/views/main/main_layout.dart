import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/views/main/tabs/chats_tab.dart';
import 'package:chat/views/main/tabs/status_tab.dart';
import 'package:chat/views/main/tabs/calls_tab.dart';
import 'package:chat/views/main/tabs/profile_tab.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    ChatsTab(),
    StatusTab(),
    CallsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Synchronize current mode with ChatController
    final auth = Get.find<AuthController>();
    Get.find<ChatController>().updateMode(auth.isDemoMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Allows content to flow behind floating navigation bar
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      
      // Gorgeous Floating Premium Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark 
                ? theme.colorScheme.surface.withOpacity(0.9) 
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.06) 
                  : Colors.black.withOpacity(0.04),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "Chats"),
              _buildNavItem(1, Icons.circle_outlined, Icons.camera_rounded, "Status"),
              _buildNavItem(2, Icons.phone_outlined, Icons.phone_rounded, "Calls"),
              _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scaling icon micro-animation
          AnimatedScale(
            scale: isSelected ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          
          // Sliding selected indicator pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isSelected ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
