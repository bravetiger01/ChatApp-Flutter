// screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF2C2C2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // App Name
                      Text(
                        'SAMPARK',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Connected Users
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildUserAvatar('assets/user1.jpg', -10),
                          _buildUserAvatar('assets/user2.jpg', 10),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        'Now You Are',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Connected',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      Text(
                        'We help you to connect with your\npeople and make new friends',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Bottom Section
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Get Started Button
                      AnimatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LOGIN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Skip Button
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/home'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Skip for now',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.textSecondary,
                                size: 12,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String imagePath, double offset) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: AppTheme.cardBackground,
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}