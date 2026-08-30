import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

class SpendlyLogo extends StatelessWidget {
  const SpendlyLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.titleText,
    this.slogan,
    this.textColor,
    this.isLight = false,
  });

  final double size;
  final bool showText;
  final String? titleText;
  final String? slogan;
  final Color? textColor;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayTitle = titleText ?? l10n?.appName ?? 'Egypt Edu Gate';
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
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.2),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.06),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_icon.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF00ADB5), AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school_rounded,
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
            displayTitle,
            style: AppTextStyles.heading1.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.32,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
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
