class Logement {
  final int idLogement;
  final String codeLogement;
  final String? typeLogement;
  final String quartier;
  final double loyerMensuel;
  final String? adresse;
  final String statut;

  Logement({
    required this.idLogement,
    required this.codeLogement,
    this.typeLogement,
    required this.quartier,
    required this.loyerMensuel,
    this.adresse,
    required this.statut,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Logement.fromJson(Map<String, dynamic> json) {
    return Logement(
      idLogement: _parseInt(json['id_logement']),
      codeLogement: json['code_logement']?.toString() ?? '',
      typeLogement: json['type_logement']?.toString(),
      quartier: json['quartier']?.toString() ?? '',
      loyerMensuel: _parseDouble(json['loyer_mensuel']),
      adresse: json['adresse']?.toString(),
      statut: json['statut']?.toString() ?? 'inconnu',
    );
  }
}