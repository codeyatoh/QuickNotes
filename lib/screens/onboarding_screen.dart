import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../theme/app_colors.dart';
import '../providers/user_settings_provider.dart';
import '../utils/toast_util.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentSlide = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Create & Edit Notes',
      'description':
          'Quickly jot down ideas, make lists, or write detailed notes with our clean interface.',
      'icon': Icons.note,
      'color': const Color(0xFF74C0FC),
    },
    {
      'title': 'Organize with Tags',
      'description':
          'Color-code your notes with tags to keep everything organized and easy to find.',
      'icon': Icons.label,
      'color': const Color(0xFF8CE99A),
    },
    {
      'title': 'Archive & Restore',
      'description':
          'Keep your workspace clean by archiving old notes, and restore them when needed.',
      'icon': Icons.archive,
      'color': const Color(0xFFD0BFFF),
    },
  ];

  void _nextSlide() async {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      final userSettings = Provider.of<UserSettingsProvider>(context, listen: false);
      final success = await userSettings.completeOnboarding();
      
      if (success && mounted) {
        ToastUtil.showSuccess(
          context,
          title: 'Thank You!',
          message: 'Welcome aboard! You\'re all set to start taking notes.',
          buttonText: 'Get Started',
          onButtonPressed: () {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        );
      } else if (mounted) {
        ToastUtil.showError(
          context,
          title: 'Error',
          message: 'Failed to save your preferences. Please try again.',
        );
        // Still navigate to home even if update fails
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      }
    }
  }

  void _skipOnboarding() async {
    // Complete onboarding even when skipped
    final userSettings = Provider.of<UserSettingsProvider>(context, listen: false);
    await userSettings.completeOnboarding();
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  onPressed: _skipOnboarding,
                  variant: ButtonVariant.text,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSlide = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              slide['icon'] as IconData,
                              size: 80,
                              color: slide['color'] as Color,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide['title'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              slide['description'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentSlide
                            ? AppColors.textPrimary
                            : AppColors.lightGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Next button
          Padding(
            padding: const EdgeInsets.all(24),
            child: CustomButton(
              onPressed: _nextSlide,
              variant: ButtonVariant.primary,
              fullWidth: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentSlide == _slides.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

