import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../scanner/models/guest_pass.dart';
import 'guest_avatar.dart';
import 'info_card.dart';

/// Card for one co-guest showing all of their details, in the silver accent
/// so it is never confused with the gold primary guest card.
class CoGuestTile extends StatelessWidget {
  const CoGuestTile({super.key, required this.guest, required this.index});

  final Guest guest;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.silver.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          // Silver side stripe marks every co-guest card.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: AppColors.silver.withValues(alpha: 0.7)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Row(
                    children: [
                      GuestAvatar(initials: guest.initials, size: 46, secondary: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CoGuestBadge(number: index + 1),
                            const SizedBox(height: 6),
                            Text(
                              guest.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.silverLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (guest.fields.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 1, color: AppColors.silverHairline),
                  for (var i = 0; i < guest.fields.length; i++) ...[
                    if (i > 0) const Divider(height: 1, thickness: 1, indent: 64, color: Color(0x14FFFFFF)),
                    InfoRow(field: guest.fields[i], accent: AppColors.silver),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoGuestBadge extends StatelessWidget {
  const _CoGuestBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.silver.withValues(alpha: 0.5)),
      ),
      child: Text(
        'CO-GUEST $number',
        style: const TextStyle(color: AppColors.silver, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.3),
      ),
    );
  }
}
