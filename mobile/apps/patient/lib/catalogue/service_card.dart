import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'catalogue_providers.dart';

/// Ligne d'un soin dans une liste : nom, durée, tarif indicatif, ordonnance si elle est exigée.
class ServiceCard extends StatelessWidget {
  const ServiceCard({required this.service, super.key});

  final CareService service;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final price = l10n.priceDirhams(formatDirhams(service.priceAmount, language));

    return NcListCard(
      key: ValueKey<String>('service-${service.slug}'),
      icon: Icons.medical_services_outlined,
      title: service.name,
      subtitle: '${l10n.serviceDuration(service.durationMinutes)} · $price',
      badge: service.requiresPrescription ? const PrescriptionBadge() : null,
      onTap: () => context.push(routeService(service.slug)),
    );
  }
}

class PrescriptionBadge extends StatelessWidget {
  const PrescriptionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return NcStatusBadge(
      label: context.l10n.servicePrescriptionRequired,
      icon: Icons.description_outlined,
      tone: NcBadgeTone.progress,
    );
  }
}
