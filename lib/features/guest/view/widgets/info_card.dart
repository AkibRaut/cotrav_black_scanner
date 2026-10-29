import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../scanner/models/guest_pass.dart';
import 'field_icon.dart';

/// A card listing fields; tap a row to copy its value.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.fields});

  final List<GuestField> fields;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, indent: 64, color: Color(0x14FFFFFF)),
            InfoRow(field: fields[i]),
          ],
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.field, this.accent = AppColors.gold});

  final GuestField field;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Clipboard.setData(ClipboardData(text: field.value));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('${field.label} copied'), duration: const Duration(milliseconds: 1200)),
          );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
              child: Icon(iconForField(field.key), color: accent, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 3),
                  Text(
                    field.value,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
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
