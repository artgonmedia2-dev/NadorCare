import 'package:geolocator/geolocator.dart';

/// Raison pour laquelle la position n'a pas pu être lue.
enum LocationFailureReason { denied, disabled, unavailable }

class LocationFailure implements Exception {
  const LocationFailure(this.reason);

  final LocationFailureReason reason;
}

typedef GeoPoint = ({double latitude, double longitude});

/// Position de l'appareil. L'interface permet de simuler le GPS dans les tests.
abstract interface class LocationService {
  /// Position actuelle. Lève [LocationFailure] si elle n'est pas disponible.
  Future<GeoPoint> currentPosition();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationFailureReason.disabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationFailure(LocationFailureReason.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on Exception {
      throw const LocationFailure(LocationFailureReason.unavailable);
    }
  }
}
