import 'package:flutter/foundation.dart';
import '../models/utilisateur.dart';
import '../models/location_data.dart';        // ✅ AJOUTER
import '../models/checkpoint_data.dart';      // ✅ AJOUTER
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';  // ✅ AJOUTER
import '../services/background_location_service.dart'; // ✅ AJOUTER en haut


class AppState extends ChangeNotifier {
  Utilisateur? _currentUtilisateur;
  List<LocataireDetails> _locataires = [];
  bool _isLoading = false;
  String _error = '';

  // Pagination et recherche
  PaginationInfo? _paginationInfo;
  int _currentPage = 1;
  String _searchQuery = '';
  String _codeLocataireFilter = '';
  String _codeLogementFilter = '';
  String _codeProprietaireFilter = '';

  // ✅ AJOUTER : Variables GPS
  LocationData? _currentLocation;
  bool _isLocationServiceActive = false;
  String _locationStatus = 'Arrêté';

  // Getters
  Utilisateur? get currentUtilisateur => _currentUtilisateur;
  List<LocataireDetails> get locataires => _locataires;
  bool get isLoading => _isLoading;
  String get error => _error;
  PaginationInfo? get paginationInfo => _paginationInfo;
  int get currentPage => _currentPage;
  String get searchQuery => _searchQuery;

  // ✅ AJOUTER : Getters GPS
  LocationData? get currentLocation => _currentLocation;
  bool get isLocationServiceActive => _isLocationServiceActive;
  String get locationStatus => _locationStatus;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService(); // ✅ AJOUTER
  // ========================
  // AUTHENTIFICATION
  // ========================

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final utilisateur = await _authService.login(username, password);
      if (utilisateur != null) {
        _currentUtilisateur = utilisateur;
        await loadLocataires();
        await _initializeLocationServices(); // ✅ AJOUTER
        _setError('');
        _setLoading(false);
        return true;
      }
      _setError('Identifiants incorrects');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Erreur: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _locationService.stopLocationTracking(); // ✅ AJOUTER
    _isLocationServiceActive = false;        // ✅ AJOUTER
    _setLocationStatus('Arrêté');           // ✅ AJOUTER
    await _authService.logout();
    _currentUtilisateur = null;
    _locataires = [];
    _currentLocation = null;                // ✅ AJOUTER
    _paginationInfo = null;
    _currentPage = 1;
    _searchQuery = '';
    _codeLocataireFilter = '';
    _codeLogementFilter = '';
    _codeProprietaireFilter = '';
    _setError('');
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final utilisateur = await _authService.getCurrentUtilisateur();
    if (utilisateur != null) {
      _currentUtilisateur = utilisateur;
      await loadLocataires();
    }
  }

  // ✅ AJOUTER TOUTE CETTE SECTION GPS
// ========================
// GÉOLOCALISATION
// ========================

  /*Future<void> _initializeLocationServices() async {
    if (_currentUtilisateur == null) return;

    _setLocationStatus('Initialisation...');

    try {
      print('📍 Demande permissions géolocalisation...');
      final hasPermission = await _locationService.requestPermissions();

      if (hasPermission) {
        print('✅ Permissions accordées');

        print('📍 Récupération position initiale...');
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          _currentLocation = position;
          print('✅ Position initiale: ${position.latitude}, ${position.longitude}');
          notifyListeners();
        }

        final token = await _authService.getToken();

        print('🚀 Démarrage tracking continu...');
        await _locationService.startLocationTracking(
          _currentUtilisateur!.idUtilisateur,
          token: token,
        );

        _isLocationServiceActive = true;
        _setLocationStatus('Actif');

        print('✅ Services de géolocalisation initialisés');
      } else {
        _setLocationStatus('Permissions refusées');
        print('❌ Permissions de géolocalisation refusées');
      }
    } catch (e) {
      _setLocationStatus('Erreur');
      print('❌ Erreur initialisation GPS: $e');
    }
  }*/
  Future<void> _initializeLocationServices() async {
    if (_currentUtilisateur == null) return;

    _setLocationStatus('Initialisation...');

    try {
      print('📍 Demande permissions géolocalisation...');
      final hasPermission = await _locationService.requestPermissions();

      if (hasPermission) {
        print('✅ Permissions accordées');

        // Position initiale
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          _currentLocation = position;
          print('✅ Position initiale: ${position.latitude}, ${position.longitude}');
          notifyListeners();
        }

        final token = await _authService.getToken();

        // ✅ NOUVEAU : Démarrer le service permanent en arrière-plan
        final started = await BackgroundLocationService.startTracking(
          agentId: _currentUtilisateur!.idUtilisateur,
          token: token!,
          agentName: _currentUtilisateur!.nomComplet,
        );

        if (started) {
          _isLocationServiceActive = true;
          _setLocationStatus('Actif (arrière-plan)');
          print('✅ Service GPS permanent démarré');
        } else {
          throw Exception('Échec démarrage service');
        }
      } else {
        _setLocationStatus('Permissions refusées');
      }
    } catch (e) {
      _setLocationStatus('Erreur');
      print('❌ Erreur GPS: $e');
    }
  }


  // ========================
  // LOCATAIRES
  // ========================

  Future<void> loadLocataires({
    int page = 1,
    String? searchQuery,
    String? codeLocataire,
    String? codeLogement,
    String? codeProprietaire,
  }) async {
    if (_currentUtilisateur == null) return;

    _setLoading(true);
    _currentPage = page;
    _searchQuery = searchQuery ?? '';
    _codeLocataireFilter = codeLocataire ?? '';
    _codeLogementFilter = codeLogement ?? '';
    _codeProprietaireFilter = codeProprietaire ?? '';

    try {
      final token = await _authService.getToken();
      final response = await _apiService.getLocatairesActifs(
        token: token,
        page: page,
        limit: 20,
        search: searchQuery,
        codeLocataire: codeLocataire,
        codeLogement: codeLogement,
        codeProprietaire: codeProprietaire,
      );

      _locataires = response.locataires;
      _paginationInfo = response.pagination;
      _setError('');
    } catch (e) {
      _setError('Erreur: $e');
    }
    _setLoading(false);
  }

  Future<void> searchLocataires(String query) async {
    if (query.isEmpty) {
      await clearFilters();
      return;
    }

    final queryTrimmed = query.trim();
    final queryUpper = queryTrimmed.toUpperCase();

    print('🔍 Recherche: "$queryTrimmed"');

    // Détection du type de recherche
    String? searchType;

    // 1. Code propriétaire (PROP + chiffres)
    if (RegExp(r'^PROP\d+$', caseSensitive: false).hasMatch(queryTrimmed)) {
      searchType = 'proprietaire';
      await loadLocataires(page: 1, codeProprietaire: queryTrimmed);
    }
    // 2. Code locataire (LOC + chiffres)
    else if (RegExp(r'^LOC\d+$', caseSensitive: false).hasMatch(queryTrimmed)) {
      searchType = 'locataire';
      await loadLocataires(page: 1, codeLocataire: queryTrimmed);
    }
    // 3. Code logement - Patterns: LOG001, CM1OM07612020, ZZ1KR07690247, etc.
    else if (RegExp(r'^(LOG|CM|ZZ|DZ|TR|AB|PL|KR|OM)\d', caseSensitive: false).hasMatch(queryTrimmed)) {
      searchType = 'logement';
      await loadLocataires(page: 1, codeLogement: queryTrimmed);
    }
    // 4. Téléphone (commence par 0 ou + et contient des chiffres)
    else if (RegExp(r'^[+0]\d{8,}$').hasMatch(queryTrimmed)) {
      searchType = 'nom'; // Le backend cherche dans nom_complet
      await loadLocataires(page: 1, searchQuery: queryTrimmed);
    }
    // 5. Recherche par nom/prénom (lettres avec espaces possibles)
    else {
      searchType = 'nom';
      await loadLocataires(page: 1, searchQuery: queryTrimmed);
    }

    print('✅ Type détecté: $searchType');
  }

  Future<void> filterByCodeLogement(String code) async {
    await loadLocataires(page: 1, codeLogement: code);
  }

  Future<void> clearFilters() async {
    await loadLocataires(page: 1);
  }

  Future<void> loadNextPage() async {
    if (_paginationInfo != null && _paginationInfo!.hasNextPage) {
      await loadLocataires(
        page: _currentPage + 1,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        codeLocataire: _codeLocataireFilter.isNotEmpty ? _codeLocataireFilter : null,
        codeLogement: _codeLogementFilter.isNotEmpty ? _codeLogementFilter : null,
        codeProprietaire: _codeProprietaireFilter.isNotEmpty ? _codeProprietaireFilter : null,
      );
    }
  }

  Future<void> loadPreviousPage() async {
    if (_paginationInfo != null && _paginationInfo!.hasPreviousPage) {
      await loadLocataires(
        page: _currentPage - 1,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        codeLocataire: _codeLocataireFilter.isNotEmpty ? _codeLocataireFilter : null,
        codeLogement: _codeLogementFilter.isNotEmpty ? _codeLogementFilter : null,
        codeProprietaire: _codeProprietaireFilter.isNotEmpty ? _codeProprietaireFilter : null,
      );
    }
  }

  // ========================
  // ENCAISSEMENTS
  // ========================

  Future<Map<String, dynamic>> enregistrerPaiement({
    required LocataireDetails locataireDetails,
    required double montantPaye,
    required String numeroRecu,
    String modePaiement = 'espèces',
  }) async {
    if (_currentUtilisateur == null) {
      return {'success': false};
    }

    try {
      await createCheckpoint('maison_locataire');

      final token = await _authService.getToken();
      final result = await _apiService.enregistrerEncaissement(
        contratId: locataireDetails.contratId,
        montantTotal: montantPaye,
        agentId: _currentUtilisateur!.idUtilisateur,
        token: token,
        modePaiement: modePaiement,
        envoyerSms: true,
      );

      // ✅ AJOUTER ce log
      print('📋 app_state résultat API:');
      print('   ${result.keys}');
      print('   mois_restants: ${result['mois_restants']}');
      print('   montant_restant_du: ${result['montant_restant_du']}');

      if (result['success'] == true) {
        // Recharger la liste
        await loadLocataires(page: _currentPage);

        // ✅ RETOURNER directement result (pas créer un nouveau Map)
        return result;
      }

      return {'success': false};
    } catch (e) {
      _setError('Erreur: $e');
      return {'success': false};
    }
  }

  // ========================
  // HELPERS
  // ========================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  Future<void> createCheckpoint(String type) async {
    if (_currentUtilisateur == null) return;

    try {
      await _locationService.createCheckpoint(_currentUtilisateur!.idUtilisateur, type);
      print('✅ Checkpoint créé: $type');
    } catch (e) {
      print('❌ Erreur création checkpoint: $e');
    }
  }

  Future<List<CheckpointData>> getHistoriqueDeplacements() async {
    if (_currentUtilisateur == null) return [];

    try {
      // TODO: Implémenter l'endpoint backend /positions/historique
      return [];
    } catch (e) {
      print('❌ Erreur récupération historique: $e');
      return [];
    }
  }
  void _setLocationStatus(String status) {
    _locationStatus = status;
    notifyListeners();
  }
}