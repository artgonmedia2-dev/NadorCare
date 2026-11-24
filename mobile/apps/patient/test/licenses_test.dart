import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nc_design_system/nc_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les licences des polices embarquées sont fournies avec l application', () async {
    registerNcFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final fonts = <String, String>{
      for (final entry in entries)
        for (final package in entry.packages)
          if (<String>['Figtree', 'Noto Sans', 'Noto Sans Arabic'].contains(package))
            package: entry.paragraphs.map((paragraph) => paragraph.text).join('\n'),
    };

    expect(fonts.keys, containsAll(<String>['Figtree', 'Noto Sans', 'Noto Sans Arabic']));
    for (final text in fonts.values) {
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(text, contains('Copyright'));
    }
  });
}
