import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'تتبع مصروفاتك وفواتيرك بدقة',
      description:
          'سجّل جميع نفقاتك ونفقات فريقك اليومية بسهولة مع تحديد طرق الدفع والتاريخ بدقة عالية.',
      icon: Icons.receipt_long_rounded,
      accentColor: AppColors.primary,
    ),
    _OnboardingItem(
      title: 'تصنيفات مخصصة وإرفاق الإيصالات',
      description:
          'نظّم مصروفاتك عبر فئات مخصصة بالألوان والأيقونات، وارفق صور الفواتير لحفظ جميع مستنداتك.',
      icon: Icons.category_rounded,
      accentColor: AppColors.secondary,
    ),
    _OnboardingItem(
      title: 'تقارير مالية ورسوم بيانية ذكية',
      description:
          'استكشف تحليلات الإنفاق الشهرية ورسوم بيانية تفاعلية تساعدك في إدارة الميزانية بكفاءة.',
      icon: Icons.auto_graph_rounded,
      accentColor: Color(0xFF6C5CE7),
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _onNextPressed() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Skip Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand title small
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.appName ?? 'Egypt Edu Gate',
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _items.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'تخطي',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration / Icon Badge
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: item.accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.accentColor.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          item.title,
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          item.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls (Dots & Action Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  // Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) {
                        final isSelected = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage == _items.length - 1
                            ? 'ابدأ الآن'
                            : 'التالي',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
}
