import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'catalogue_providers.dart';

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
      subtitle: service.categoryName,
      children: <Widget>[
        if (description != null && description.isNotEmpty) ...<Widget>[
          Text(description, style: textTheme.bodyLarge),
          const SizedBox(height: NcSpacing.lg),
        ],
        _Fact(
          icon: Icons.schedule,
          label: l10n.serviceDurationLabel,
          value: l10n.serviceDuration(service.durationMinutes),
        ),
        _Fact(
          icon: Icons.payments_outlined,
          label: l10n.servicePriceLabel,
          value: l10n.priceDirhams(formatDirhams(service.priceAmount, language)),
        ),
        Text(l10n.servicePriceNote, style: textTheme.bodyMedium),
        if (profession != null && profession.isNotEmpty) ...<Widget>[
          const SizedBox(height: NcSpacing.md),
          Text(l10n.serviceProvidedBy(profession), style: textTheme.bodyLarge),
        ],
        if (service.allowsSeries) ...<Widget>[
          const SizedBox(height: NcSpacing.sm),
          Text(l10n.serviceSeries, style: textTheme.bodyLarge),
        ],
        const SizedBox(height: NcSpacing.lg),
        if (service.requiresPrescription) ...<Widget>[
          NcNotice(
            key: const ValueKey<String>('prescription-notice'),
            message: '${l10n.servicePrescriptionRequired}. ${l10n.servicePrescriptionHelp}',
            kind: NcNoticeKind.warning,
          ),
          const SizedBox(height: NcSpacing.md),
        ],
        NcNotice(message: l10n.bookingSoon),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: NcSpacing.md),
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
          Text(value, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}
