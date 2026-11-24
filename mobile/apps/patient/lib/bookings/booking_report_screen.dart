import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'bookings_providers.dart';
import 'price_breakdown.dart';

/// Compte rendu d'un soin terminé, en lecture seule. Son ouverture est inscrite au journal
/// des accès par le serveur.
class BookingReportScreen extends ConsumerWidget {
  const BookingReportScreen({required this.bookingId, super.key});

  final String bookingId;

  static String _lines(NcLocalizations l10n, List<ReportLine> lines) {
    return lines
        .map(
          (line) =>
              line.quantity == 1 ? line.label : l10n.reportLineWithQuantity(line.label, formatMeasure(line.quantity)),
        )
        .join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final report = ref.watch(bookingReportProvider(bookingId));

    return switch (report) {
      AsyncData<Intervention>(value: final intervention) => NcPage(
          appBar: AppBar(),
          title: l10n.reportTitle,
          children: <Widget>[
            if (intervention.isAmended) ...<Widget>[
              NcNotice(
                key: const ValueKey<String>('report-amended'),
                message: l10n.reportAmended(intervention.amendmentReason ?? ''),
                kind: NcNoticeKind.warning,
              ),
              const SizedBox(height: NcSpacing.lg),
            ],
            // Les constantes en tuiles, comme un tableau de bord de santé.
            if (Vital.values.any((vital) => intervention.vitals[vital] != null)) ...<Widget>[
              NcSectionTitle(l10n.reportVitalsTitle),
              NcTileGrid(
                children: <Widget>[
                  for (final vital in Vital.values)
                    if (intervention.vitals[vital] != null)
                      NcStatTile(
                        key: ValueKey<String>('report-vital-${vital.name}'),
                        value: formatMeasure(intervention.vitals[vital]!),
                        label: vitalLabel(l10n, vital),
                        icon: vitalIcon(vital),
                      ),
                ],
              ),
            ],
            if ((intervention.observations ?? '').isNotEmpty)
              NcSection(
                title: l10n.reportObservations,
                icon: Icons.notes,
                children: <Widget>[Text(intervention.observations!, style: Theme.of(context).textTheme.bodyLarge)],
              ),
            if (intervention.acts.isNotEmpty || intervention.consumables.isNotEmpty)
              NcSection(
                title: l10n.reportActsTitle,
                icon: Icons.medical_services_outlined,
                children: <Widget>[
                  if (intervention.acts.isNotEmpty)
                    SummaryRow(
                      icon: Icons.check_circle_outline,
                      label: l10n.reportActsTitle,
                      value: _lines(l10n, intervention.acts),
                    ),
                  if (intervention.consumables.isNotEmpty)
                    SummaryRow(
                      icon: Icons.inventory_2_outlined,
                      label: l10n.reportConsumablesTitle,
                      value: _lines(l10n, intervention.consumables),
                    ),
                ],
              ),
            if ((intervention.signedByName ?? '').isNotEmpty)
              NcSurface(
                child: SummaryRow(
                  icon: Icons.draw_outlined,
                  label: l10n.reportSignatureTitle,
                  value: l10n.reportSignedBy(intervention.signedByName!),
                ),
              ),
          ],
        ),
      AsyncError<Intervention>(:final error) => NcPage(
          appBar: AppBar(),
          title: l10n.reportTitle,
          actions: <Widget>[
            NcPrimaryButton(label: l10n.retry, onPressed: () => ref.invalidate(bookingReportProvider(bookingId))),
          ],
          children: <Widget>[NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error)],
        ),
      _ => NcPage(
          appBar: AppBar(),
          title: l10n.reportTitle,
          children: const <Widget>[Center(child: CircularProgressIndicator())],
        ),
    };
  }
}
