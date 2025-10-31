import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/locataire.dart';
import '../models/logement.dart';
import '../models/proprietaire.dart';
import '../models/receipt_verification.dart';
import '../models/encaissement.dart';

// ⚠️ IMPORTANT : Changer cette URL pour la production
const String _BASE_URL = 'http://180.149.199.150:3000';
//const String _BASE_URL = 'http://192.168.1.26:3000';

// ========================
// CLASSES DE DONNÉES
// ========================

class LocataireDetails {
  final Locataire locataire;
  final Logement logement;
  final Proprietaire proprietaire;
  final double montantDu;
  final int contratId;
  final String? contratReference;
  final List<MoisDu> detailsMoisDus;

  LocataireDetails({
    required this.locataire,
    required this.logement,
    required this.proprietaire,
    required this.montantDu,
    required this.contratId,
    this.contratReference,
    this.detailsMoisDus = const [],
  });
}

class MoisDu {
  final int id;
  final int mois;
  final int annee;
  final String periode;
  final double montantLoyer;
  final double montantPaye;
  final double montantDu;

  MoisDu({
    required this.id,
    required this.mois,
    required this.annee,
    required this.periode,
    required this.montantLoyer,
    required this.montantPaye,
    required this.montantDu,
  });

  factory MoisDu.fromJson(Map<String, dynamic> json) {
    return MoisDu(
      id: json['id'] as int,
      mois: json['mois'] as int,
      annee: json['annee'] as int,
      periode: json['periode'] as String,
      montantLoyer: _parseDouble(json['montant_loyer']),
      montantPaye: _parseDouble(json['montant_paye']),
      montantDu: _parseDouble(json['montant_du']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrev: json['has_prev'] as bool,
    );
  }

  // Compatibilité avec l'ancien code
  int get pageSize => limit;
  int get totalCount => total;
  bool get hasNextPage => hasNext;
  bool get hasPreviousPage => hasPrev;
}

class LocatairesResponse {
  final List<LocataireDetails> locataires;
  final PaginationInfo pagination;

  LocatairesResponse({
    required this.locataires,
    required this.pagination,
  });
}

// ========================
// API SERVICE
// ========================

class ApiService {
  // Helper pour parser les valeurs numériques
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ========================
  // AUTHENTIFICATION
  // ========================

  /// Login avec l'API réelle
  /// Endpoint: POST /auth/login
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse('$_BASE_URL/auth/login');

    try {
      print('🔐 Tentative de connexion pour: $username');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('📡 Statut réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['ok'] == true) {
          print('✅ Connexion réussie');
          return {
            'token': data['token'],
            'user': data['user'],
          };
        } else {
          throw Exception(data['message'] ?? 'Erreur de connexion');
        }
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Identifiants incorrects');
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur login: $e');
      rethrow;
    }
  }

  /**
   * Simule l'allocation d'un encaissement sans l'enregistrer dans la DB.
   * Retourne les allocations et les arriérés restants.
   */
  Future<Map<String, dynamic>> simulateEncaissement({
    required int contratId,
    required double montantTotal,
    required int agentId,
    required String modePaiement,
    String? referencePaiement,
    String? commentaire,
  }) async {
    final url = Uri.parse('$_BASE_URL/api/encaissements/simulate'); // 👈 Endpoint à vérifier
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contrat_id': contratId,
        'montant_total': montantTotal,
        'agent_id': agentId,
        'mode_paiement': modePaiement,
        'reference_paiement': referencePaiement,
        'commentaire': commentaire,
        // envoyer_sms n'est pas utile pour la simulation
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        return {
          'success': true,
          'allocations': data['allocations'],
          'mois_restants': data['mois_restants'],
          'montant_restant_du': data['montant_restant_du'],
          // Les données de simulation
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur de simulation inconnue');
      }
    } else {
      throw Exception('Erreur serveur (${response.statusCode}) lors de la simulation: ${response.body}');
    }
  }
  // ========================
  // LOCATAIRES
  // ========================

  /// Récupère la liste des locataires actifs avec filtres
  /// Endpoint: GET /locataires/actifs
  Future<LocatairesResponse> getLocatairesActifs({
    String? token,
    int page = 1,
    int limit = 20,
    String? search,
    String? codeLocataire,
    String? codeLogement,
    String? codeProprietaire,
  }) async {
    try {
      // Construction des paramètres de requête
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (codeLocataire != null && codeLocataire.isNotEmpty) {
        queryParams['code_locataire'] = codeLocataire;
      }
      if (codeLogement != null && codeLogement.isNotEmpty) {
        queryParams['code_logement'] = codeLogement;
      }
      if (codeProprietaire != null && codeProprietaire.isNotEmpty) {
        queryParams['code_proprietaire'] = codeProprietaire;
      }

      final uri = Uri.parse('$_BASE_URL/locataires/actifs')
          .replace(queryParameters: queryParams);

      print('🔍 Requête: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📡 Statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['ok'] == true) {
          final List locatairesData = data['data'];
          print('✅ ${locatairesData.length} locataires récupérés');

          final locataires = locatairesData.map((item) {
            // Parse locataire
            final locataireData = item['locataire'];
            final locataire = Locataire(
              idLocataire: _parseInt(locataireData['id']),
              codeLocataire: locataireData['code']?.toString(),
              nomComplet: locataireData['nom_complet']?.toString() ?? '',
              telephone1: locataireData['telephone']?.toString(),
            );

            // Parse logement
            final logementData = item['logement'];
            final logement = Logement(
              idLogement: _parseInt(logementData['id']),
              codeLogement: logementData['code']?.toString() ?? '',
              quartier: logementData['quartier']?.toString() ?? '', // Pas dans la réponse API
              loyerMensuel: _parseDouble(logementData['loyer']),
              statut: 'actif',
            );

            // Parse propriétaire
            final proprietaireData = item['proprietaire'];
            final proprietaire = Proprietaire(
              idProprietaire: _parseInt(proprietaireData['id']),
              codeProprietaire: proprietaireData['code']?.toString() ?? '',
              nomComplet: proprietaireData['nom_complet']?.toString() ?? '',
              telephone1: proprietaireData['telephone']?.toString(),
            );

            // Parse arriérés
            final arrieresData = item['arrieres'];
            final montantDu = _parseDouble(arrieresData['montant_total_du']);

            // Parse contrat
            final contratData = item['contrat'];
            final contratId = _parseInt(contratData['id']);
            final contratRef = contratData['reference']?.toString();

            // Parse détails mois dus
            final List<MoisDu> detailsMoisDus = [];
            if (arrieresData['details_mois_dus'] != null) {
              final List moisDusList = arrieresData['details_mois_dus'];
              detailsMoisDus.addAll(
                moisDusList.map((m) => MoisDu.fromJson(m)).toList(),
              );
            }

            return LocataireDetails(
              locataire: locataire,
              logement: logement,
              proprietaire: proprietaire,
              montantDu: montantDu,
              contratId: contratId,
              contratReference: contratRef,
              detailsMoisDus: detailsMoisDus,
            );
          }).toList();

          final pagination = PaginationInfo.fromJson(data['pagination']);

          return LocatairesResponse(
            locataires: locataires,
            pagination: pagination,
          );
        } else {
          throw Exception(data['message'] ?? 'Erreur API');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur getLocatairesActifs: $e');
      rethrow;
    }
  }

  // ========================
  // ENCAISSEMENTS
  // ========================

  /// Enregistre un encaissement (SMS automatique inclus)
  /// Endpoint: POST /encaissements
  Future<Map<String, dynamic>> enregistrerEncaissement({
    required int contratId,
    required double montantTotal,
    int? agentId,
    String? token,
    String modePaiement = 'espèces',
    String? referencePaiement,
    String? commentaire,
    bool envoyerSms = false,
  }) async {
    final url = Uri.parse('$_BASE_URL/api/encaissements');

    try {
      print('💰 Enregistrement encaissement...');
      print('   Contrat: $contratId');
      print('   Montant: $montantTotal FCFA');
      print('   Mode: $modePaiement');
      print('   SMS: $envoyerSms');

      final body = {
        'contrat_id': contratId,
        'montant_total': montantTotal,
        'mode_paiement': modePaiement,
        'envoyer_sms': envoyerSms,
      };

      if (agentId != null) body['agent_id'] = agentId;
      if (referencePaiement != null) body['reference_paiement'] = referencePaiement;
      if (commentaire != null) body['commentaire'] = commentaire;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📡 Statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ AJOUTER ce log
        print('📦 Réponse brute backend:');
        print(jsonEncode(data));
        if (data['ok'] == true) {
          print('✅ Encaissement enregistré');
          print('   ID: ${data['encaissement']['id']}');
          print('   SMS: ${data['sms_envoye']}');
          print('   Mois restants: ${data['mois_restants']}'); // ✅ AJOUTER
          print('   Montant restant: ${data['montant_restant_du']}'); // ✅ AJOUTER

          return {
            'success': true,
            'encaissement_id': data['encaissement']['id'],
            'sms_envoye': data['sms_envoye'] ?? false,
            'allocations': data['allocations'] ?? [],
            'mois_restants': data['mois_restants'] ?? [],  // ✅ AJOUTER
            'montant_restant_du': data['montant_restant_du'] ?? 0,  // ✅ AJOUTER
          };
        } else {
          throw Exception(data['message'] ?? 'Erreur encaissement');
        }
      } else if (response.statusCode == 404) {
        print('❌ Endpoint introuvable: $url');
        throw Exception(
            'Endpoint /encaissements non disponible.\n'
                'Vérifiez que le backend est à jour.'
        );
      } else {
        // Tenter de parser JSON
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Erreur serveur');
        } catch (_) {
          throw Exception('Erreur serveur (${response.statusCode})');
        }
      }
    } catch (e) {
      print('❌ Erreur enregistrerEncaissement: $e');
      rethrow;
    }
  }

  // ========================
// GÉOLOCALISATION
// ========================

  /// Enregistre la position GPS d'un agent
  /// Endpoint: POST /positions
  Future<bool> updateAgentPosition({
    required int agentId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    double? accuracy,
    String? adresse,
    String? token,
  }) async {
    final url = Uri.parse('$_BASE_URL/positions');

    try {
      final body = {
        'agent_id': agentId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'adresse': adresse,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          print('📍 Position enregistrée: $latitude, $longitude');
          return true;
        }
      }

      print('⚠️ Échec enregistrement position: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Erreur updateAgentPosition: $e');
      return false;
    }
  }

  /// Enregistre un checkpoint (arrêt)
  /// Endpoint: POST /checkpoints (à implémenter backend si besoin)
  Future<bool> enregistrerCheckpoint({
    required int agentId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    String? adresse,
    String typeArret = 'autre',
    String? token,
  }) async {
    // Pour l'instant, on enregistre juste comme une position normale
    // TODO: Créer un vrai endpoint /checkpoints si besoin
    return await updateAgentPosition(
      agentId: agentId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      accuracy: null,
      adresse: '$typeArret - $adresse',
      token: token,
    );
  }

  // ========================
  // UTILITAIRES (conservés pour compatibilité)
  // ========================

  Future<String> genererNumeroRecu() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return 'ENC${now.millisecondsSinceEpoch % 1000000}';
  }

  Future<String> genererCodeUnique() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'AGETIM$timestamp';
  }

  // ========================
  // VÉRIFICATION QR CODE
  // ========================

  /// Vérifie l'authenticité d'un reçu via son code QR
  /// ⚠️ TODO: Remplacer par un vrai endpoint API quand disponible
  /// Endpoint suggéré: GET /encaissements/verifier?code={code}
  Future<ReceiptVerification> verifierRecu(String codeUnique) async {
    // Pour l'instant : vérification mock
    // À remplacer par un vrai appel API quand l'endpoint sera disponible

    await Future.delayed(const Duration(milliseconds: 500));

    // Validation basique du format
    if (codeUnique.startsWith('AGETIM')) {
      // Mock de réponse positive
      return ReceiptVerification(
        isValid: true,
        encaissement: Encaissement(
          numeroRecu: 'ENC${DateTime.now().millisecondsSinceEpoch % 100000}',
          datePaiement: DateTime.now(),
          nomLocataire: 'Vérification réussie',
          codeLogement: 'CODE-XXX',
          montantPaye: 0,
          modePaiement: 'espèces',
          codeUnique: codeUnique,
        ),
        utilisateur: null,
        message: 'Reçu authentique (vérification locale)',
      );
    } else {
      return ReceiptVerification(
        isValid: false,
        message: 'Code invalide ou format incorrect',
      );
    }

    /*
    // CODE À UTILISER QUAND L'ENDPOINT SERA DISPONIBLE :
    final url = Uri.parse('$_BASE_URL/encaissements/verifier?code=$codeUnique');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReceiptVerification.fromJson(data);
      } else {
        return ReceiptVerification(
          isValid: false,
          message: 'Reçu non trouvé',
        );
      }
    } catch (e) {
      print('❌ Erreur vérification: $e');
      rethrow;
    }
    */
  }
}