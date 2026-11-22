import 'package:flutter_test/flutter_test.dart';
import 'package:nc_core/nc_core.dart';

void main() {
  test('un compte rendu renvoyé par le serveur se lit, avenant compris', () {
    final intervention = Intervention.fromJson(<String, dynamic>{
      'id': 'I1',
      'booking_id': 'B1',
      'status': 'validated',
      'report': <String, dynamic>{
        'version': 2,
        'vitals': <String, dynamic>{'systolic': 125, 'temperature': 37.2, 'poids': 80},
        'observations': 'Pansement refait.',
        'signed_by_name': 'Aïcha Benali',
        'is_signed': true,
        'photos_count': 2,
        'validated_at': '2026-12-08T10:40:00+00:00',
        'amendment_reason': 'Erreur de saisie',
      },
      'acts': <dynamic>[
        <String, dynamic>{'act_id': 'A1', 'label': 'Réfection de pansement', 'quantity': 1},
      ],
      'consumables': <dynamic>[
        <String, dynamic>{'consumable_id': null, 'label': 'Compresses', 'quantity': 4.5},
      ],
    });

    expect(intervention.isValidated, isTrue);
    expect(intervention.isAmended, isTrue);
    expect(intervention.vitals, <Vital, num>{Vital.systolic: 125, Vital.temperature: 37.2});
    expect(intervention.photosCount, 2);
    expect(intervention.acts.single.referenceId, 'A1');
    expect(intervention.consumables.single.quantity, 4.5);
    expect(intervention.consumables.single.referenceId, isNull);
  });

  test('un brouillon tout juste ouvert se lit sans constantes', () {
    // Sans constante, PHP encode un tableau vide en liste plutôt qu'en objet.
    final intervention = Intervention.fromJson(<String, dynamic>{
      'id': 'I1',
      'booking_id': 'B1',
      'status': 'in_progress',
      'report': <String, dynamic>{'version': 1, 'vitals': <dynamic>[], 'observations': null, 'is_signed': false},
      'acts': <dynamic>[],
      'consumables': <dynamic>[],
    });

    expect(intervention.vitals, isEmpty);
    expect(intervention.isValidated, isFalse);
    expect(intervention.isSigned, isFalse);
  });

  test('le brouillon envoyé suit le format attendu par le serveur', () {
    const draft = ReportDraft(
      vitals: <Vital, num>{Vital.spo2: 98, Vital.glucose: 1.1},
      observations: '',
      acts: <ReportLine>[ReportLine(label: 'Injection', referenceId: 'A2')],
      consumables: <ReportLine>[ReportLine(label: 'Seringue', quantity: 2)],
    );

    expect(draft.toJson(), <String, dynamic>{
      'vitals': <String, num>{'spo2': 98, 'glucose': 1.1},
      'observations': null,
      'acts': <Map<String, dynamic>>[
        <String, dynamic>{'act_id': 'A2', 'label': 'Injection', 'quantity': 1},
      ],
      'consumables': <Map<String, dynamic>>[
        <String, dynamic>{'consumable_id': null, 'label': 'Seringue', 'quantity': 2},
      ],
    });
  });

  test('les bornes des constantes refusent les fautes de frappe', () {
    expect(Vital.systolic.accepts(135), isTrue);
    expect(Vital.systolic.accepts(1350), isFalse);
    expect(Vital.temperature.accepts(37.2), isTrue);
    expect(Vital.spo2.accepts(140), isFalse);
  });
}
