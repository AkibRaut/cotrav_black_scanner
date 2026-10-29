import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Shows a themed message; errors get a red accent and a haptic bump.
void showAuthMessage(BuildContext context, String message, {bool error = false}) {
  if (error) HapticFeedback.heavyImpact();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: error ? AppColors.error.withValues(alpha: 0.6) : AppColors.hairline),
        ),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: error ? AppColors.error : AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: error ? AppColors.textPrimary : AppColors.goldLight)),
            ),
          ],
        ),
      ),
    );
}
