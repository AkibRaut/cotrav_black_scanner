import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_text.dart';

/// Initials inside a gold ring (silver when [secondary]). With [spinning] the
/// ring's highlight rotates.
class GuestAvatar extends StatefulWidget {
  const GuestAvatar({super.key, required this.initials, this.size = 48, this.spinning = false, this.secondary = false});

  final String initials;
  final double size;
  final bool spinning;
  final bool secondary;

  @override
  State<GuestAvatar> createState() => _GuestAvatarState();
}

class _GuestAvatarState extends State<GuestAvatar> with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void initState() {
    super.initState();
    if (widget.spinning) {
      _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  TextStyle get _initialsStyle =>
      TextStyle(fontSize: widget.size * 0.36, fontWeight: FontWeight.w800, letterSpacing: 1);

  @override
  Widget build(BuildContext context) {
    final ringWidth = widget.size * 0.05 + 1;
    final ring = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: widget.secondary
              ? const [AppColors.silverDark, AppColors.silverLight, AppColors.silver, AppColors.silverDark]
              : const [AppColors.goldDark, AppColors.goldLight, AppColors.gold, AppColors.goldDark],
        ),
      ),
    );

    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_spin != null)
            RepaintBoundary(
              child: RotationTransition(turns: _spin!, child: ring),
            )
          else
            ring,
          Padding(
            padding: EdgeInsets.all(ringWidth),
            child: DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceHigh),
              child: Center(
                child: widget.secondary
                    ? Text(widget.initials, style: _initialsStyle.copyWith(color: AppColors.silverLight))
                    : GoldText(widget.initials, style: _initialsStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
