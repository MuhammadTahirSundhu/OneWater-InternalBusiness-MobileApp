import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../onboarding/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Welcome to OneWater',
      'description': 'Manage your internal business operations, track sales, and monitor customers on the go.',
      'icon': 'water_drop',
    },
    {
      'title': 'Offline Ready',
      'description': 'Create transactions and view catalogs even without an internet connection. Data syncs automatically.',
      'icon': 'signal_wifi_off',
    },
    {
      'title': 'Secure & Fast',
      'description': 'Protect your app with a custom PIN lock. Real-time updates keep your team in sync.',
      'icon': 'lock',
    },
  ];

  IconData _getIcon(String name) {
    switch (name) {
      case 'water_drop': return Icons.water_drop;
      case 'signal_wifi_off': return Icons.signal_wifi_off;
      case 'lock': return Icons.lock;
      default: return Icons.info;
    }
  }

  void _finishOnboarding() async {
    final storage = ref.read(secureStorageProvider);
    await storage.setHasSeenOnboarding(true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(data['icon']!),
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          data['title']!,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['description']!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      _currentPage == _onboardingData.length - 1 ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
