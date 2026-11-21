import 'package:flutter/widgets.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Texte à afficher pour une erreur. Le serveur traduit déjà ses messages ;
/// seules les erreurs sans réponse du serveur sont traduites ici.
String failureMessage(BuildContext context, Object error) {
  final l10n = context.l10n;

  if (error is! ApiFailure) {
    return l10n.errorUnknown;
  }
  if (error.isNetwork) {
    return l10n.errorNetwork;
  }

  return error.message ?? l10n.errorUnknown;
}
