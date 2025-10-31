import 'dart:convert';

/// Modèle Utilisateur adapté au format API réel
/// Format API: { id, username, nom, prenom, nom_complet, email, telephone, role }
class Utilisateur {
  final int id;
  final String username;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String? email;
  final String? telephone;
  final String role;

  Utilisateur({
    required this.id,
    required this.username,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    this.email,
    this.telephone,
    required this.role,
  });

  // Getters pour compatibilité avec l'ancien code
  int get idUtilisateur => id;
  String get rolePrincipal => role;
  String get codeAgent => username; // Le username sert de code agent
  String get statut => 'actif';

  /// Parse depuis la réponse API
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] as int,
      username: json['username'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      nomComplet: json['nom_complet'] as String,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      role: json['role'] as String,
    );
  }

  /// Convertit en JSON pour stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nom': nom,
      'prenom': prenom,
      'nom_complet': nomComplet,
      'email': email,
      'telephone': telephone,
      'role': role,
    };
  }

  @override
  String toString() => 'Utilisateur($nomComplet, $role)';
}