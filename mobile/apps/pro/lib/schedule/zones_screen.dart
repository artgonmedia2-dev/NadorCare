import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Zones où le professionnel accepte d'intervenir.
class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen> {
  late final Set<String> _selected;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final file = ref.read(professionalFileProvider).value;
    _selected = <String>{for (final zone in file?.zones ?? const <ServiceZone>[]) zone.id};
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(professionalFileProvider.notifier).setZones(_selected.toList());
      if (mounted) {
        context.pop();
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
    final zones = ref.watch(serviceZonesProvider);
    final list = zones.value;

    return NcPage(
      appBar: AppBar(),
      title: l10n.proZonesTitle,
      actions: <Widget>[
        if (list != null && list.isNotEmpty) NcPrimaryButton(label: l10n.save, isLoading: _busy, onPressed: _save),
        if (zones.hasError) NcPrimaryButton(label: l10n.retry, onPressed: () => ref.invalidate(serviceZonesProvider)),
      ],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        if (zones.hasError)
          NcNotice(message: failureMessage(context, zones.error!), kind: NcNoticeKind.error)
        else if (list == null)
          const Center(child: CircularProgressIndicator())
        else if (list.isEmpty)
          NcNotice(message: l10n.proZonesEmpty)
        else
          for (final zone in list)
            CheckboxListTile(
              key: ValueKey<String>('zone-${zone.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _selected.contains(zone.id),
              title: Text(zone.name, style: Theme.of(context).textTheme.bodyLarge),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _selected.add(zone.id);
                } else {
                  _selected.remove(zone.id);
                }
              }),
            ),
      ],
    );
  }
}
