import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Text painted with the gold gradient.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, this.style, this.textAlign, this.maxLines});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: AppColors.goldGradient.createShader,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      ),
    );
  }
}
