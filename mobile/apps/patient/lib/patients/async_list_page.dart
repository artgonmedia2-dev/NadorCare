import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Écran de liste commun : chargement, erreur avec « Réessayer », liste vide, puis les lignes.
class AsyncListPage<T> extends StatelessWidget {
  const AsyncListPage({
    required this.title,
    required this.items,
    required this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
    required this.onRetry,
    required this.itemBuilder,
    super.key,
  });

  final String title;
  final AsyncValue<List<T>> items;
  final String emptyMessage;
  final String addLabel;
  final VoidCallback onAdd;
  final VoidCallback onRetry;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return NcPage(
      appBar: AppBar(),
      title: title,
      actions: <Widget>[
        if (items.hasValue) NcPrimaryButton(label: addLabel, onPressed: onAdd),
        if (items.hasError && !items.isLoading) NcPrimaryButton(label: l10n.retry, onPressed: onRetry),
      ],
      children: switch (items) {
        AsyncData<List<T>>(:final value) when value.isEmpty => <Widget>[NcNotice(message: emptyMessage)],
        AsyncData<List<T>>(:final value) => <Widget>[for (final item in value) itemBuilder(item)],
        AsyncError<List<T>>(:final error) => <Widget>[
            NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error),
          ],
        _ => const <Widget>[
            Padding(
              padding: EdgeInsets.all(NcSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
      },
    );
  }
}
