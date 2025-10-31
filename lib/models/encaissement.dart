class Encaissement {
  final String numeroRecu;
  final DateTime datePaiement;
  final String nomLocataire;
  final String codeLogement;
  final double montantPaye;
  final String modePaiement;
  final String codeUnique;

  Encaissement({
    required this.numeroRecu,
    required this.datePaiement,
    required this.nomLocataire,
    required this.codeLogement,
    required this.montantPaye,
    required this.modePaiement,
    required this.codeUnique,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Encaissement.fromJson(Map<String, dynamic> json) {
    return Encaissement(
      numeroRecu: json['numero_recu']?.toString() ?? '',
      datePaiement: DateTime.parse(json['date_paiement']),
      nomLocataire: json['nom_locataire']?.toString() ?? '',
      codeLogement: json['code_logement']?.toString() ?? '',
      montantPaye: _parseDouble(json['montant_paye']),
      modePaiement: json['mode_paiement']?.toString() ?? '',
      codeUnique: json['code_unique']?.toString() ?? '',
    );
  }
}