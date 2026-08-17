import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SpendlyLogo extends StatelessWidget {
  const SpendlyLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.slogan,
    this.textColor,
    this.isLight = false,
  });

  final double size;
  final bool showText;
  final String? slogan;
  final Color? textColor;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final titleColor = textColor ?? (isLight ? Colors.white : AppColors.primary);
    final subtitleColor = textColor != null
        ? textColor!.withValues(alpha: 0.8)
        : (isLight ? Colors.white70 : AppColors.textSecondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container with soft glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.25),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Elegant vector fallback if asset loading fails
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00ADB5), AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(size * 0.28),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: size * 0.52,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text(
            'Spendly',
            style: AppTextStyles.heading1.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.36,
              letterSpacing: 0.5,
            ),
          ),
          if (slogan != null) ...[
            const SizedBox(height: 4),
            Text(
              slogan!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
                fontSize: size * 0.16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }
}
