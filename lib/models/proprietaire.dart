class Proprietaire {
  final int idProprietaire;
  final String codeProprietaire;
  final String nomComplet;
  final String? telephone1;

  Proprietaire({
    required this.idProprietaire,
    required this.codeProprietaire,
    required this.nomComplet,
    this.telephone1,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Proprietaire.fromJson(Map<String, dynamic> json) {
    return Proprietaire(
      idProprietaire: _parseInt(json['id_proprietaire']),
      codeProprietaire: json['code_proprietaire']?.toString() ?? '',
      nomComplet: json['nom_complet']?.toString() ?? 'Inconnu',
      telephone1: json['telephone_1']?.toString(),
    );
  }
}