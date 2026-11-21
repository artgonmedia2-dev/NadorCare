import 'package:nc_core/nc_core.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Libellés traduits des valeurs fixes d'un profil.
String relationshipLabel(NcLocalizations l10n, PatientRelationship relationship) {
  return switch (relationship) {
    PatientRelationship.self => l10n.relationshipSelf,
    PatientRelationship.parent => l10n.relationshipParent,
    PatientRelationship.child => l10n.relationshipChild,
    PatientRelationship.spouse => l10n.relationshipSpouse,
    PatientRelationship.other => l10n.relationshipOther,
  };
}

const String routeProfiles = '/profiles';
const String routeProfileNew = '/profiles/new';
const String routeAddresses = '/addresses';
const String routeAddressNew = '/addresses/new';

String routeProfile(String id) => '/profiles/edit/$id';

String routeAddress(String id) => '/addresses/edit/$id';
