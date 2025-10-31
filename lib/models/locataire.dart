class Locataire {
  final int idLocataire;
  final String? codeLocataire;
  final String nomComplet;
  final String? telephone1;
  final String? telephone2;
  final String? quartierResidence;
  final String? profession;
  final String? statut;

  Locataire({
    required this.idLocataire,
    this.codeLocataire,
    required this.nomComplet,
    this.telephone1,
    this.telephone2,
    this.quartierResidence,
    this.profession,
    this.statut,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Locataire.fromJson(Map<String, dynamic> json) {
    return Locataire(
      idLocataire: _parseInt(json['id_locataire']),
      codeLocataire: json['code_locataire']?.toString(),
      nomComplet: json['nom_complet']?.toString() ?? '',
      telephone1: json['telephone_1']?.toString(),
      telephone2: json['telephone_2']?.toString(),
      quartierResidence: json['quartier_residence']?.toString(),
      profession: json['profession']?.toString(),
      statut: json['statut']?.toString(),
    );
  }
}