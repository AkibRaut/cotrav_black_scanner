import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/gold_text.dart';
import '../../scanner/models/guest_pass.dart';
import 'widgets/co_guest_tile.dart';
import 'widgets/field_icon.dart';
import 'widgets/info_card.dart';
import 'widgets/primary_guest_card.dart';
import 'widgets/reveal.dart';

class GuestDetailsPage extends StatefulWidget {
  const GuestDetailsPage({super.key, required this.pass});

  final GuestPass pass;

  static Route<void> route(GuestPass pass) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => GuestDetailsPage(pass: pass),
      transitionsBuilder: (_, animation, _, child) {
        final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: curved.drive(Tween(begin: 0.94, end: 1.0)), child: child),
        );
      },
    );
  }

  @override
  State<GuestDetailsPage> createState() => _GuestDetailsPageState();
}

class _GuestDetailsPageState extends State<GuestDetailsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pass = widget.pass;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    Widget section(String title, double start, {Color color = AppColors.gold, IconData? icon}) => Reveal(
      animation: _intro,
      start: start,
      end: math.min(start + 0.4, 1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 8)],
            Text(title.toUpperCase(), style: labelStyle?.copyWith(color: color)),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.25))),
          ],
        ),
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.2,
            colors: [Color(0xFF2A2210), AppColors.black],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold),
                      ),
                      const Spacer(),
                      Text('GUEST PASS', style: labelStyle),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Hero(pass: pass, animation: _intro),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.list(
                  children: [
                    section('Primary guest', 0.15, icon: Icons.star_rounded),
                    Reveal(
                      animation: _intro,
                      start: 0.2,
                      end: 0.6,
                      child: PrimaryGuestCard(
                        guest: pass.primary,
                        avatarScale: _intro.drive(
                          CurveTween(curve: const Interval(0.2, 0.7, curve: Curves.elasticOut)),
                        ),
                      ),
                    ),
                    if (pass.coGuests.isNotEmpty)
                      section(
                        'Co-guests · ${pass.coGuests.length}',
                        0.45,
                        color: AppColors.silver,
                        icon: Icons.people_alt_rounded,
                      ),
                    for (var i = 0; i < pass.coGuests.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Reveal(
                          animation: _intro,
                          start: math.min(0.55 + i * 0.06, 0.75),
                          end: math.min(0.95 + i * 0.06, 1),
                          child: CoGuestTile(guest: pass.coGuests[i], index: i),
                        ),
                      ),
                    if (pass.booking.isNotEmpty) ...[
                      section('Pass details', 0.6, icon: Icons.confirmation_number_rounded),
                      Reveal(
                        animation: _intro,
                        start: 0.65,
                        end: 1,
                        child: InfoCard(fields: pass.booking),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Reveal(
          animation: _intro,
          start: 0.5,
          end: 1,
          offset: const Offset(0, 0.6),
          child: GoldButton(
            label: 'Scan next guest',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pass, required this.animation});

  final GuestPass pass;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final badgeScale = animation.drive(CurveTween(curve: const Interval(0, 0.4, curve: Curves.easeOutBack)));
    final coCount = pass.coGuests.length;
    final eventName = pass.eventName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          ScaleTransition(
            scale: badgeScale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
                boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 30)],
              ),
              child: const Icon(Icons.verified_rounded, size: 34, color: AppColors.black),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            animation: animation,
            start: 0.05,
            end: 0.45,
            child: eventName == null
                ? GoldText('Pass Verified', style: Theme.of(context).textTheme.headlineMedium)
                : Column(
                    children: [
                      Text('EVENT', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gold)),
                      const SizedBox(height: 6),
                      GoldText(
                        eventName,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 15, color: AppColors.gold),
                          SizedBox(width: 6),
                          Text('Pass verified', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
          ),
          if (pass.eventDetails.isNotEmpty) ...[
            const SizedBox(height: 14),
            Reveal(
              animation: animation,
              start: 0.08,
              end: 0.48,
              child: _EventDetails(fields: pass.eventDetails),
            ),
          ],
          const SizedBox(height: 12),
          Reveal(
            animation: animation,
            start: 0.1,
            end: 0.5,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const _Chip(icon: Icons.star_rounded, label: '1 Primary', filled: true),
                if (coCount > 0)
                  _Chip(
                    icon: Icons.people_alt_rounded,
                    label: '$coCount ${coCount == 1 ? 'Co-guest' : 'Co-guests'}',
                    color: AppColors.silver,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.filled = false, this.color = AppColors.goldLight});

  final IconData icon;
  final String label;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.black : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: filled ? AppColors.goldGradient : null,
        color: filled ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Date, venue, etc. shown right under the event name.
class _EventDetails extends StatelessWidget {
  const _EventDetails({required this.fields});

  final List<GuestField> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconForField(fields[i].key), size: 17, color: AppColors.gold),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fields[i].value,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
