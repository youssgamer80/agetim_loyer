import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/utilisateur.dart';
import 'api_service.dart';

class AuthService {
  static const String _utilisateurKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  final ApiService _apiService = ApiService();

  /// Login avec l'API réelle
  Future<Utilisateur?> login(String username, String password) async {
    try {
      final authData = await _apiService.login(username, password);

      if (authData != null) {
        final utilisateur = Utilisateur.fromJson(authData['user']);
        final token = authData['token'] as String;

        // Stocker dans SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_utilisateurKey, jsonEncode(utilisateur.toJson()));

        print('✅ Utilisateur connecté: ${utilisateur.nomComplet}');
        return utilisateur;
      }
      return null;
    } catch (e) {
      print('❌ Erreur login: $e');
      rethrow;
    }
  }

  /// Récupère l'utilisateur stocké localement
  Future<Utilisateur?> getCurrentUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    final utilisateurJson = prefs.getString(_utilisateurKey);

    if (utilisateurJson != null) {
      return Utilisateur.fromJson(jsonDecode(utilisateurJson));
    }
    return null;
  }

  /// Récupère le token stocké
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_utilisateurKey);
    await prefs.remove(_tokenKey);
    print('🚪 Déconnexion effectuée');
  }
}