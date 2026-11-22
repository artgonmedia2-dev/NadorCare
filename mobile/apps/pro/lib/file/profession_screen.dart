import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Première étape du dossier : la profession et les numéros d'autorisation.
/// Sert aussi à corriger la profession tant que le dossier n'est pas soumis.
class ProfessionScreen extends ConsumerStatefulWidget {
  const ProfessionScreen({super.key});

  @override
  ConsumerState<ProfessionScreen> createState() => _ProfessionScreenState();
}

class _ProfessionScreenState extends ConsumerState<ProfessionScreen> {
  final TextEditingController _license = TextEditingController();
  final TextEditingController _order = TextEditingController();

  String? _categoryId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final file = ref.read(professionalFileProvider).value;
    if (file != null) {
      _categoryId = file.categoryId;
      _license.text = file.licenseNumber ?? '';
      _order.text = file.orderNumber ?? '';
    }
  }

  @override
  void dispose() {
    _license.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _error = context.l10n.professionRequired);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(professionalFileProvider.notifier).save(
            categoryId: categoryId,
            licenseNumber: _license.text.trim(),
            orderNumber: _order.text.trim(),
          );
      if (mounted) {
        context.go(routeFile);
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(professionCategoriesProvider);
    final list = categories.value ?? const <ProfessionCategory>[];
    final selected = list.where((category) => category.id == _categoryId).firstOrNull;

    return NcPage(
      appBar: AppBar(),
      title: l10n.professionLabel,
      actions: <Widget>[
        if (list.isNotEmpty) NcPrimaryButton(label: l10n.continueButton, isLoading: _busy, onPressed: _save),
        if (categories.hasError)
          NcPrimaryButton(label: l10n.retry, onPressed: () => ref.invalidate(professionCategoriesProvider)),
      ],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        if (categories.hasError)
          NcNotice(message: failureMessage(context, categories.error!), kind: NcNoticeKind.error)
        else if (list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else ...<Widget>[
          NcChoiceList<String>(
            keyPrefix: 'profession',
            selected: _categoryId,
            onSelected: (id) => setState(() {
              _categoryId = id;
              _error = null;
            }),
            choices: <NcChoice<String>>[
              for (final category in list) NcChoice<String>(value: category.id, label: category.name),
            ],
          ),
          const SizedBox(height: NcSpacing.md),
          TextField(
            key: const ValueKey<String>('license-field'),
            controller: _license,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.licenseNumberLabel),
          ),
          // Le numéro d'Ordre n'est demandé qu'aux professions qui ont un Ordre.
          if (selected?.hasOrder ?? false) ...<Widget>[
            const SizedBox(height: NcSpacing.md),
            TextField(
              key: const ValueKey<String>('order-field'),
              controller: _order,
              decoration: InputDecoration(labelText: l10n.orderNumberLabel),
            ),
          ],
        ],
      ],
    );
  }
}
