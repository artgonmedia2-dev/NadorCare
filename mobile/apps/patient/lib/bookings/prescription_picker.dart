import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

typedef PickedPrescription = ({Uint8List bytes, String filename});

/// Photo de l'ordonnance. L'interface permet de simuler l'appareil photo dans les tests.
abstract interface class PrescriptionPicker {
  /// Renvoie `null` si l'utilisateur referme sans choisir.
  Future<PickedPrescription?> pick({required bool fromCamera});
}

class DevicePrescriptionPicker implements PrescriptionPicker {
  DevicePrescriptionPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPrescription?> pick({required bool fromCamera}) async {
    // Image réduite : lisible par le soignant, rapide à envoyer sur un réseau lent.
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 80,
    );

    if (file == null) {
      return null;
    }

    return (bytes: await file.readAsBytes(), filename: file.name.isEmpty ? 'ordonnance.jpg' : file.name);
  }
}
