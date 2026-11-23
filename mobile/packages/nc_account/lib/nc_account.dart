/// Compte utilisateur commun aux deux applications : connexion par téléphone et code OTP,
/// consentement, choix de la langue, taille du texte, verrouillage biométrique, réglages,
/// et l'enveloppe d'application qui relie le tout.
library;

export 'src/app/bootstrap.dart';
export 'src/app/nador_care_app.dart';
export 'src/auth/auth_controller.dart';
export 'src/auth/auth_state.dart';
export 'src/biometric_service.dart';
export 'src/failure_message.dart';
export 'src/location_service.dart';
export 'src/providers.dart';
export 'src/report_texts.dart';
export 'src/screens/teleconsultation_screen.dart';
export 'src/settings/app_settings.dart';
export 'src/settings/settings_controller.dart';
export 'src/storage/preferences_store.dart';
export 'src/storage/session_storage.dart';
