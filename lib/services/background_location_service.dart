import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ AJOUTER
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ Adapter cette URL
const String _BASE_URL = 'http://180.149.199.150:3000';

class BackgroundLocationService {
  static const double _minDistanceMeters = 50.0;

  // Initialiser le service foreground
  // Initialiser le service foreground
  static Future<void> initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'agetim_tracking',
        channelName: 'AGETIM Tracking GPS',
        channelDescription: 'Suivi de position en temps réel',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // ✅ SIMPLIFIER : utiliser l'icône par défaut
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // 60 secondes
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  // Démarrer le tracking
// Démarrer le tracking
  static Future<bool> startTracking({
    required int agentId,
    required String token,
    required String agentName,
  }) async {
    // Sauvegarder les infos dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('agent_id', agentId);
    await prefs.setString('auth_token', token);
    await prefs.setString('agent_name', agentName);

    await initForegroundTask();

    try {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'AGETIM - Suivi GPS actif',
        notificationText: 'Agent: $agentName',
        callback: startCallback,
      );

      // Vérifier si le service est bien démarré
      return await FlutterForegroundTask.isRunningService;
    } catch (e) {
      print('❌ Erreur démarrage service: $e');
      return false;
    }
  }

// Arrêter le tracking
  static Future<bool> stopTracking() async {
    try {
      await FlutterForegroundTask.stopService();

      // Vérifier si le service est bien arrêté
      final isRunning = await FlutterForegroundTask.isRunningService;
      return !isRunning; // true si arrêté avec succès
    } catch (e) {
      print('❌ Erreur arrêt service: $e');
      return false;
    }
  }

  // Status du service
  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}

// ⚠️ CALLBACK - Fonctionne en arrière-plan
@pragma('vm:entry-point')
void startCallback() {
  // CORRECTION : L'appel au gestionnaire de tâche doit être simple.
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  Position? _lastPosition;
  int _updateCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🚀 Service GPS démarré');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      // Récupérer les infos depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final agentId = prefs.getInt('agent_id');
      final token = prefs.getString('auth_token');

      if (agentId == null || token == null) {
        print('❌ Pas de config agent');
        return;
      }
      print("ICIICC");
      // Récupérer position GPS
      // ✅ AUGMENTER LE TIME LIMIT (10s -> 30s) pour éviter les Timeouts
      final position = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).first.timeout(const Duration(seconds: 5));
      print("LABABA");


      // Vérifier si mouvement significatif
      /*if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < BackgroundLocationService._minDistanceMeters) {
          print('⏸️ Mouvement insuffisant: ${distance.toInt()}m');
          return;
        }
      }*/

      // ✅ NOUVEAU : Récupérer l'adresse
      String? adresse;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10)); // Time limit spécifique pour le géocodage

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Format : "Rue, Quartier, Ville"
          adresse = [
            place.street,
            place.subLocality ?? place.locality,
            place.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          print('📍 Adresse: $adresse');
        }
      } catch (e) {
        print('⚠️ Impossible de récupérer l\'adresse: $e');
        // Continuer sans adresse plutôt que d'échouer
      }

      // Envoyer au backend avec l'adresse
      final success = await _sendPosition(
        agentId: agentId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        adresse: adresse, // ✅ AJOUTER
        token: token,
      );

      if (success) {
        _lastPosition = position;
        _updateCount++;

        // Mettre à jour la notification avec l'adresse
        FlutterForegroundTask.updateService(
          notificationTitle: 'AGETIM - GPS actif',
          notificationText: adresse ?? 'Positions envoyées: $_updateCount',
        );

        print('✅ Position #$_updateCount envoyée: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      // Gérer l'exception de Timeout spécifiquement
      if (e is TimeoutException) {
        print('❌ Erreur tracking: Timeout lors de la récupération GPS après 30s.');
      } else {
        print('❌ Erreur tracking: $e');
      }
    }

    // Envoyer un événement à l'app (optionnel)
    FlutterForegroundTask.sendDataToMain({'updateCount': _updateCount});
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🛑 Service GPS arrêté');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('Bouton notification pressé: $id');
  }

  @override
  void onNotificationPressed() {
    print('Notification pressée');
    FlutterForegroundTask.launchApp('/');
  }

  // Envoyer position au backend
  // Envoyer position au backend
  // Envoyer position au backend
  Future<bool> _sendPosition({
    required int agentId,
    required double latitude,
    required double longitude,
    required double accuracy,
    String? adresse,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_BASE_URL/positions');

      // ✅ Utiliser Map<String, dynamic> au lieu de Map<String, num>
      final Map<String, dynamic> body = {
        'agent_id': agentId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };

      // Ajouter l'adresse si disponible
      if (adresse != null && adresse.isNotEmpty) {
        body['adresse'] = adresse;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Erreur envoi position: $e');
      return false;
    }
  }
}
