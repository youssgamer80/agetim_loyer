import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import 'api_service.dart';

class LocationService {
  static const double _minDistanceMeters = 50.0;
  static const int _minTimeSeconds = 30;
  static const int _maxTimeSeconds = 120;

  final ApiService _apiService = ApiService();
  StreamSubscription<Position>? _positionStream;
  LocationData? _lastPosition;
  DateTime? _lastUpdateTime;
  Timer? _forceUpdateTimer;
  int? _currentAgentId;
  String? _token; // ✅ AJOUTER

  /*Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }*/

  Future<bool> requestPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Services de localisation désactivés');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Permission actuelle: $permission');

      if (permission == LocationPermission.denied) {
        print('📍 Demande de permission...');
        permission = await Geolocator.requestPermission();
        print('📍 Résultat permission: $permission');

        if (permission == LocationPermission.denied) {
          print('❌ Permission refusée par l\'utilisateur');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission refusée définitivement');
        return false;
      }

      print('✅ Permissions accordées: $permission');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  Future<LocationData?> getCurrentPosition() async {
    try {
      print('🎯 Récupération position actuelle...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('❌ Erreur géolocalisation: $e');

      try {
        print('🔄 Tentative avec précision réduite...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );

        return LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        );
      } catch (e2) {
        print('❌ Échec définitif géolocalisation: $e2');
        return null;
      }
    }
  }

  Future<void> startLocationTracking(int agentId, {String? token}) async {
    print('🚀 Démarrage du tracking GPS pour agent $agentId');
    _currentAgentId = agentId;
    _token = token; // ✅ STOCKER

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 30,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _handleNewPosition(position, agentId);
    });

    _forceUpdateTimer = Timer.periodic(
      const Duration(seconds: 90),
          (timer) => _forcePositionUpdate(agentId),
    );
  }

  void _handleNewPosition(Position position, int agentId) {
    final newPosition = LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
    );

    print('📲 Nouvelle position reçue: ${position.latitude}, ${position.longitude}');

    if (_shouldUpdatePosition(newPosition)) {
      _updateAgentPosition(newPosition, agentId);
      _lastPosition = newPosition;
      _lastUpdateTime = DateTime.now();
    } else {
      print('⏭️ Position ignorée (conditions non remplies)');
    }
  }

  bool _shouldUpdatePosition(LocationData newPosition) {
    if (_lastPosition == null || _lastUpdateTime == null) {
      print('✅ Première position - acceptée');
      return true;
    }

    final timeDiff = DateTime.now().difference(_lastUpdateTime!).inSeconds;
    print('⏰ Temps écoulé: ${timeDiff}s (min: ${_minTimeSeconds}s, max: ${_maxTimeSeconds}s)');

    if (timeDiff >= _maxTimeSeconds) {
      print('🕐 Mise à jour forcée (temps max dépassé)');
      return true;
    }

    if (timeDiff < _minTimeSeconds) {
      print('⏸️ Temps insuffisant écoulé');
      return false;
    }

    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    print('📏 Distance parcourue: ${distance.toStringAsFixed(1)}m (min: ${_minDistanceMeters}m)');

    if (distance >= _minDistanceMeters) {
      print('✅ Distance suffisante - position acceptée');
      return true;
    } else {
      print('📍 Distance insuffisante - position ignorée');
      return false;
    }
  }

  Future<void> _updateAgentPosition(LocationData position, int agentId) async {
    try {
      await _apiService.updateAgentPosition(
        agentId: agentId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        accuracy: position.accuracy,
        token: _token, // ✅ PASSER LE TOKEN
      );
    } catch (e) {
      print('Erreur mise à jour position: $e');
    }
  }

  Future<void> _forcePositionUpdate(int agentId) async {
    print('🔄 Mise à jour forcée de position');
    try {
      final position = await getCurrentPosition();
      if (position != null) {
        await _updateAgentPosition(position, agentId);
        _lastPosition = position;
        _lastUpdateTime = DateTime.now();
      }
    } catch (e) {
      print('❌ Erreur mise à jour forcée: $e');
    }
  }

  Future<void> createCheckpoint(int agentId, String type) async {
    final position = await getCurrentPosition();
    if (position != null) {
      await _apiService.enregistrerCheckpoint(
        agentId: agentId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        typeArret: type,
        token: _token, // ✅ PASSER LE TOKEN
      );
    }
  }

  void stopLocationTracking() {
    print('🛑 Arrêt du tracking GPS');
    _positionStream?.cancel();
    _forceUpdateTimer?.cancel();
    _positionStream = null;
    _forceUpdateTimer = null;
    _currentAgentId = null;
  }
}