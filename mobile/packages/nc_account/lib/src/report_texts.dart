import 'package:flutter/material.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Icône d'une constante, pour les tuiles du compte rendu.
IconData vitalIcon(Vital vital) {
  return switch (vital) {
    Vital.systolic || Vital.diastolic => Icons.favorite_border,
    Vital.pulse => Icons.monitor_heart_outlined,
    Vital.temperature => Icons.device_thermostat,
    Vital.glucose => Icons.bloodtype_outlined,
    Vital.spo2 => Icons.air,
  };
}

/// Libellé traduit d'une constante, avec son unité.
String vitalLabel(NcLocalizations l10n, Vital vital) {
  return switch (vital) {
    Vital.systolic => l10n.vitalSystolic,
    Vital.diastolic => l10n.vitalDiastolic,
    Vital.pulse => l10n.vitalPulse,
    Vital.temperature => l10n.vitalTemperature,
    Vital.glucose => l10n.vitalGlucose,
    Vital.spo2 => l10n.vitalSpo2,
  };
}

/// Nombre saisi ou relevé, sans décimale inutile : `72`, `37.2`.
String formatMeasure(num value) {
  return value == value.roundToDouble() ? value.round().toString() : value.toString();
}
