import 'package:flutter/material.dart';

import 'nc_colors.dart';
import 'nc_spacing.dart';
import 'nc_surface.dart';

enum NcNoticeKind { info, error, warning }

/// Message encadré : erreur d'un formulaire, information, avertissement.
class NcNotice extends StatelessWidget {
  const NcNotice({required this.message, this.kind = NcNoticeKind.info, super.key});

  final String message;
  final NcNoticeKind kind;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData icon) = switch (kind) {
      NcNoticeKind.info => (NcColors.primarySoft, NcColors.primaryDeep, Icons.info_outline),
      NcNoticeKind.error => (NcColors.dangerSoft, NcColors.danger, Icons.error_outline),
      NcNoticeKind.warning => (NcColors.warningSoft, NcColors.warning, Icons.warning_amber_outlined),
    };

    return Semantics(
      liveRegion: kind == NcNoticeKind.error,
      child: Container(
        padding: const EdgeInsets.all(NcSpacing.md),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ncRadius)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: foreground),
            const SizedBox(width: NcSpacing.sm),
            Expanded(
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
