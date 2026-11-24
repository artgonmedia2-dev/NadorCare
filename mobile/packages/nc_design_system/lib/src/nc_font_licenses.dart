import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Polices embarquées et fichier de leur licence (SIL Open Font License 1.1), dans `fonts/`.
const List<(String, String)> _fontLicenses = <(String, String)>[
  ('Figtree', 'OFL-Figtree.txt'),
  ('Noto Sans', 'OFL-NotoSans.txt'),
  ('Noto Sans Arabic', 'OFL-NotoSansArabic.txt'),
];

/// Inscrit les licences des polices au registre des licences de Flutter. La licence exige que
/// chaque copie distribuée des polices contienne son texte et l'avis de copyright : ils sont
/// embarqués dans l'application et apparaissent dans la liste de ses licences.
void registerNcFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in _fontLicenses) {
      final text = await rootBundle.loadString('packages/nc_design_system/fonts/$file');
      yield LicenseEntryWithLineBreaks(<String>[font], text);
    }
  });
}
