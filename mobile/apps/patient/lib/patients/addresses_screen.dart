import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'async_list_page.dart';
import 'patient_texts.dart';
import 'patients_providers.dart';

/// Liste des adresses du compte, avec pour chacune l'état de la couverture.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AsyncListPage<PatientAddress>(
      title: l10n.homeAddresses,
      items: ref.watch(addressesControllerProvider),
      emptyMessage: l10n.addressesEmpty,
      addLabel: l10n.addressAdd,
      onAdd: () => context.push(routeAddressNew),
      onRetry: () => ref.read(addressesControllerProvider.notifier).reload(),
      itemBuilder: (address) => NcListCard(
        key: ValueKey<String>('address-${address.id}'),
        icon: Icons.home_outlined,
        title: address.label,
        subtitle: address.line,
        badge: CoverageBadge(isCovered: address.isCovered),
        onTap: () => context.push(routeAddress(address.id)),
      ),
    );
  }
}

/// Indique si le service est ouvert à une adresse. Le texte porte l'information,
/// la couleur ne fait que l'appuyer.
class CoverageBadge extends StatelessWidget {
  const CoverageBadge({required this.isCovered, super.key});

  final bool isCovered;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = isCovered ? scheme.primary : scheme.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(isCovered ? Icons.check_circle_outline : Icons.info_outline, size: 18, color: color),
        const SizedBox(width: NcSpacing.xs),
        Flexible(
          child: Text(
            isCovered ? l10n.addressCovered : l10n.addressNotCovered,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
