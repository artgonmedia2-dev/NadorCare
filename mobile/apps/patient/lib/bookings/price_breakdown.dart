import 'package:flutter/material.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../catalogue/catalogue_providers.dart';

/// Détail d'un prix : tarif, majorations, total.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({required this.price, super.key});

  final PriceQuote price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final textTheme = Theme.of(context).textTheme;

    String amount(int centimes) => l10n.priceDirhams(formatDirhams(centimes, language));

    return Column(
      children: <Widget>[
        _Line(label: l10n.summaryBasePrice, value: amount(price.base), style: textTheme.bodyLarge),
        for (final line in price.surcharges)
          _Line(label: line.label, value: '+ ${amount(line.amount)}', style: textTheme.bodyLarge),
        const Divider(height: NcSpacing.lg),
        _Line(
          key: const ValueKey<String>('price-total'),
          label: l10n.summaryTotal,
          value: amount(price.total),
          style: textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, required this.style, super.key});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NcSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: NcSpacing.md),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Une information du récapitulatif : libellé discret, valeur lisible.
class SummaryRow extends StatelessWidget {
  const SummaryRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: NcSpacing.xs),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
