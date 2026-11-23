import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'catalogue_providers.dart';
import 'service_card.dart';

/// Catalogue : les catégories, ou le résultat de la recherche dès qu'on tape deux caractères.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  static const Duration _debounce = Duration(milliseconds: 400);

  final TextEditingController _search = TextEditingController();
  Timer? _timer;
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// La recherche part quand la saisie s'arrête, pas à chaque lettre.
  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = _query.length >= 2;

    return NcPage(
      appBar: AppBar(),
      title: l10n.homeCatalogue,
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('catalogue-search'),
          controller: _search,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l10n.catalogueSearchHint, prefixIcon: const Icon(Icons.search)),
        ),
        const SizedBox(height: NcSpacing.lg),
        if (searching) ..._results(context) else ..._categories(context),
      ],
    );
  }

  List<Widget> _categories(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(careCategoriesProvider);

    return _async<CareCategory>(
      context,
      value: categories,
      onRetry: () => ref.invalidate(careCategoriesProvider),
      emptyMessage: l10n.catalogueEmpty,
      itemBuilder: (category) => NcListCard(
        key: ValueKey<String>('category-${category.slug}'),
        icon: Icons.healing_outlined,
        title: category.name,
        subtitle: l10n.servicesCount(category.servicesCount),
        onTap: () => context.push(routeCategory(category.slug)),
      ),
    );
  }

  List<Widget> _results(BuildContext context) {
    final ServiceFilter filter = (categorySlug: null, query: _query);

    return _async<CareService>(
      context,
      value: ref.watch(careServicesProvider(filter)),
      onRetry: () => ref.invalidate(careServicesProvider(filter)),
      emptyMessage: context.l10n.catalogueNoResult(_query),
      itemBuilder: (service) => ServiceCard(service: service),
    );
  }
}

/// Affichage commun d'une liste chargée depuis le serveur : attente, erreur, vide, lignes.
List<Widget> _async<T>(
  BuildContext context, {
  required AsyncValue<List<T>> value,
  required VoidCallback onRetry,
  required String emptyMessage,
  required Widget Function(T item) itemBuilder,
}) {
  return switch (value) {
    AsyncData<List<T>>(value: final items) when items.isEmpty => <Widget>[
        NcEmptyState(message: emptyMessage, icon: Icons.search_off),
      ],
    AsyncData<List<T>>(value: final items) => <Widget>[for (final item in items) itemBuilder(item)],
    AsyncError<List<T>>(:final error) => <Widget>[
        NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error),
        const SizedBox(height: NcSpacing.md),
        NcSecondaryButton(label: context.l10n.retry, icon: Icons.refresh, onPressed: onRetry),
      ],
    _ => const <Widget>[
        Padding(
          padding: EdgeInsets.all(NcSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
  };
}

/// Services d'une catégorie.
class CategoryServicesScreen extends ConsumerWidget {
  const CategoryServicesScreen({required this.categorySlug, super.key});

  final String categorySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ServiceFilter filter = (categorySlug: categorySlug, query: null);
    final services = ref.watch(careServicesProvider(filter));
    final loaded = services.value;

    return NcPage(
      appBar: AppBar(),
      // Le nom de la catégorie vient des services eux-mêmes, déjà traduits.
      title: (loaded == null || loaded.isEmpty) ? l10n.homeCatalogue : loaded.first.categoryName,
      children: _async<CareService>(
        context,
        value: services,
        onRetry: () => ref.invalidate(careServicesProvider(filter)),
        emptyMessage: l10n.catalogueEmpty,
        itemBuilder: (service) => ServiceCard(service: service),
      ),
    );
  }
}
