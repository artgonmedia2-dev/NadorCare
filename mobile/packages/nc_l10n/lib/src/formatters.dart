import 'package:intl/intl.dart' show DateFormat, NumberFormat;

/// Montant en dirhams à partir de centimes : « 150 », « 80,5 ». Les chiffres restent
/// latins en arabe, comme c'est l'usage au Maroc.
String formatDirhams(int centimes, String languageCode) {
  final locale = languageCode == 'ar' ? 'ar_MA' : languageCode;
  return NumberFormat('#,##0.##', locale).format(centimes / 100);
}

/// Jour écrit en toutes lettres dans la langue de l'écran : « mardi 8 décembre 2026 ».
String longDate(DateTime day, String languageCode) => DateFormat.yMMMMEEEEd(languageCode).format(day);

/// Jour au format de l'API : `AAAA-MM-JJ`.
String apiDate(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

/// Distance lisible : « 850 m », « 2,4 km ».
String formatDistance(int meters, String languageCode) {
  if (meters < 1000) {
    return '$meters m';
  }
  final locale = languageCode == 'ar' ? 'ar_MA' : languageCode;
  return '${NumberFormat('#,##0.#', locale).format(meters / 1000)} km';
}
