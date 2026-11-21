import 'package:flutter/foundation.dart';
import 'package:nc_core/nc_core.dart';

/// État de la session sur cet appareil.
@immutable
sealed class AuthState {
  const AuthState();
}

/// Démarrage : la session enregistrée n'a pas encore été lue.
class AuthInitializing extends AuthState {
  const AuthInitializing();
}

/// Personne n'est connecté.
class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// Une session existe, mais l'application attend l'empreinte ou le visage.
class AuthLocked extends AuthState {
  const AuthLocked();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AppUser user;
}
