import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_text.dart';
import '../../../scanner/models/guest_pass.dart';
import 'guest_avatar.dart';
import 'info_card.dart';

/// The primary guest: gold-framed card with identity header and all details.
class PrimaryGuestCard extends StatelessWidget {
  const PrimaryGuestCard({super.key, required this.guest, required this.avatarScale});

  final Guest guest;
  final Animation<double> avatarScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.18), blurRadius: 30)],
      ),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(22.5),
        color: const Color(0xFF15120A),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: avatarScale,
                    child: GuestAvatar(initials: guest.initials, size: 68, spinning: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PrimaryBadge(),
                        const SizedBox(height: 8),
                        GoldText(
                          guest.name,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (guest.fields.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.hairline),
              for (var i = 0; i < guest.fields.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, indent: 64, color: Color(0x14FFFFFF)),
                InfoRow(field: guest.fields[i]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: AppColors.black),
          SizedBox(width: 4),
          Text(
            'PRIMARY',
            style: TextStyle(color: AppColors.black, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}
