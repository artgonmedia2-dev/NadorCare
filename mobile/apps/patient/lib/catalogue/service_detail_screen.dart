import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../bookings/bookings_providers.dart';
import 'catalogue_providers.dart';
import 'service_card.dart';

/// Fiche d'un soin : description, durée, tarif indicatif, règle d'ordonnance.
/// Le bouton de réservation viendra avec la tâche 4.4.
class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final service = ref.watch(careServiceProvider(slug));

    return switch (service) {
      AsyncData<CareService>(:final value) => _detail(context, value),
      AsyncError<CareService>(:final error) => NcPage(
          appBar: AppBar(),
          title: l10n.homeCatalogue,
          actions: <Widget>[
            NcPrimaryButton(label: l10n.retry, onPressed: () => ref.invalidate(careServiceProvider(slug))),
          ],
          children: <Widget>[NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error)],
        ),
      _ => NcPage(
          appBar: AppBar(),
          title: l10n.homeCatalogue,
          children: const <Widget>[Center(child: CircularProgressIndicator())],
        ),
    };
  }

  Widget _detail(BuildContext context, CareService service) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final language = Localizations.localeOf(context).languageCode;
    final description = service.description;
    final profession = service.professionalCategory;

    return NcPage(
      appBar: AppBar(),
      title: service.name,
      header: NcDetailHeader(
        icon: service.isRemote ? Icons.videocam_outlined : categoryIcon(service.categorySlug),
        title: service.name,
        subtitle: service.categoryName,
        badge: service.requiresPrescription ? const PrescriptionBadge() : null,
      ),
      actions: <Widget>[
        NcPrimaryButton(
          label: l10n.bookService,
          icon: Icons.event_available_outlined,
          onPressed: () => context.push(routeBookingNew(service.slug)),
        ),
      ],
      children: <Widget>[
        // Durée et tarif : les deux informations qui décident, en tuiles.
        NcTileGrid(
          children: <Widget>[
            NcStatTile(
              value: l10n.serviceDuration(service.durationMinutes),
              label: l10n.serviceDurationLabel,
              icon: Icons.schedule,
              tone: NcBadgeTone.info,
            ),
            NcStatTile(
              value: l10n.priceDirhams(formatDirhams(service.priceAmount, language)),
              label: l10n.servicePriceLabel,
              icon: Icons.payments_outlined,
            ),
          ],
        ),
        Text(
          l10n.servicePriceNote,
          style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: NcSpacing.lg),
        if (service.isRemote) ...<Widget>[
          NcStatusBadge(label: l10n.teleconsultationLabel, icon: Icons.videocam_outlined, tone: NcBadgeTone.success),
          const SizedBox(height: NcSpacing.sm),
          NcNotice(key: const ValueKey<String>('teleconsultation-notice'), message: l10n.teleconsultationServiceNote),
          const SizedBox(height: NcSpacing.md),
        ],
        if ((description != null && description.isNotEmpty) ||
            (profession != null && profession.isNotEmpty) ||
            service.allowsSeries)
          NcSection(
            title: l10n.serviceAboutTitle,
            icon: Icons.info_outline,
            children: <Widget>[
              if (description != null && description.isNotEmpty) Text(description, style: textTheme.bodyLarge),
              if (profession != null && profession.isNotEmpty) ...<Widget>[
                const SizedBox(height: NcSpacing.sm),
                Text(l10n.serviceProvidedBy(profession), style: textTheme.bodyLarge),
              ],
              if (service.allowsSeries) ...<Widget>[
                const SizedBox(height: NcSpacing.sm),
                Text(l10n.serviceSeries, style: textTheme.bodyLarge),
              ],
            ],
          ),
        if (service.requiresPrescription) ...<Widget>[
          NcNotice(
            key: const ValueKey<String>('prescription-notice'),
            message: '${l10n.servicePrescriptionRequired}. ${l10n.servicePrescriptionHelp}',
            kind: NcNoticeKind.warning,
          ),
        ],
      ],
    );
  }
}
