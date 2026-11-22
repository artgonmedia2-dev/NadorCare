/// Traductions français, arabe (droite à gauche) et anglais.
///
/// Aucun texte ne s'écrit en dur dans un écran : il s'ajoute dans `lib/src/arb/app_fr.arb`
/// et ses deux traductions, puis `flutter gen-l10n` régénère [NcLocalizations].
library;

import 'package:flutter/widgets.dart';

import 'src/generated/nc_localizations.dart';

export 'src/formatters.dart';
export 'src/generated/nc_localizations.dart';

extension NcLocalizationsContext on BuildContext {
  /// Textes de l'application dans la langue courante.
  NcLocalizations get l10n => NcLocalizations.of(this);
}
