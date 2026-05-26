import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:chat/views/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Circles for premium aesthetic
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary.withOpacity(isDark ? 0.1 : 0.06),
              ),
            ),
          ),

          // Main Onboarding PageView
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildPage(
                        context,
                        title: "Encrypting Your\nConversations",
                        subtitle: "Secure & Premium",
                        description: "Experience absolute privacy with military-grade end-to-end messaging. Your secrets are always safe with us.",
                        painter: SecureChatIllustrationPainter(color: Theme.of(context).colorScheme.primary),
                      ),
                      _buildPage(
                        context,
                        title: "Hyper-Fast\nInstant Sharing",
                        subtitle: "Blazing Speed",
                        description: "Share HD images, files, status stories, and crystal-clear calls with smooth Material 3 micro-animations.",
                        painter: SpeedIllustrationPainter(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
                
                // Indicators & Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dots Indicator
                      Row(
                        children: List.generate(2, (index) => _buildIndicator(index == _currentPage)),
                      ),
                      
                      // Next / Get Started button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == 1 ? 160 : 70,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == 0) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              // Enter Demo Mode by default and go to Login
                              Get.find<AuthController>().startDemoMode();
                              Get.off(() => const LoginScreen());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == 1 ? "Get Started" : "",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (_currentPage == 1) const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required CustomPainter painter,
  }) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant graphic/illustration using custom painters for a gorgeous native look
          Center(
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              margin: const EdgeInsets.only(bottom: 40),
              child: CustomPaint(
                painter: painter,
              ),
            ),
          ),
          
          Text(
            subtitle.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// PREMIUM CUSTOM PAINTERS FOR ARTWORK

class SecureChatIllustrationPainter extends CustomPainter {
  final Color color;
  SecureChatIllustrationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);

    // Glowing shield outline
    final shieldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, h * 0.25);
    path.quadraticBezierTo(w * 0.7, h * 0.25, w * 0.75, h * 0.35);
    path.quadraticBezierTo(w * 0.75, h * 0.6, w * 0.5, h * 0.78);
    path.quadraticBezierTo(w * 0.25, h * 0.6, w * 0.25, h * 0.35);
    path.quadraticBezierTo(w * 0.3, h * 0.25, w * 0.5, h * 0.25);
    canvas.drawPath(path, shieldPaint);

    // Inner details (Lock symbol)
    final lockPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Shackle
    final shacklePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.42, h * 0.4, w * 0.16, h * 0.16),
      3.14,
      3.14,
      false,
      shacklePaint,
    );

    // Lock Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.48, w * 0.24, h * 0.16),
        const Radius.circular(6),
      ),
      lockPaint,
    );

    // Glowing particles
    final particlePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.2, h * 0.3), 6, particlePaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.5), 8, particlePaint);
    canvas.drawCircle(Offset(w * 0.3, h * 0.7), 5, particlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeedIllustrationPainter extends CustomPainter {
  final Color color;
  SpeedIllustrationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);

    final w = size.width;
    final h = size.height;

    // Lightning bolt glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final path = Path();
    path.moveTo(w * 0.55, h * 0.18);
    path.lineTo(w * 0.28, h * 0.54);
    path.lineTo(w * 0.48, h * 0.54);
    path.lineTo(w * 0.42, h * 0.82);
    path.lineTo(w * 0.72, h * 0.44);
    path.lineTo(w * 0.52, h * 0.44);
    path.close();
    canvas.drawPath(path, glowPaint);

    // Lightning bolt solid
    final boltPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, boltPaint);

    // Dynamic speed arcs
    final arcPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7),
      3.5,
      1.2,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
      0.5,
      0.8,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
