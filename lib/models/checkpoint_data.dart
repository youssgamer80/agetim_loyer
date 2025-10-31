class CheckpointData {
  final String id;
  final int idAgent;
  final double latitude;
  final double longitude;
  final DateTime dateArrivee;
  final DateTime? dateDepart;
  final String? adresse;
  final int? dureeArret;
  final String typeArret;

  CheckpointData({
    required this.id,
    required this.idAgent,
    required this.latitude,
    required this.longitude,
    required this.dateArrivee,
    this.dateDepart,
    this.adresse,
    this.dureeArret,
    required this.typeArret,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_agent': idAgent,
      'latitude': latitude,
      'longitude': longitude,
      'date_arrivee': dateArrivee.toIso8601String(),
      'date_depart': dateDepart?.toIso8601String(),
      'adresse': adresse,
      'duree_arret': dureeArret,
      'type_arret': typeArret,
    };
  }

  factory CheckpointData.fromJson(Map<String, dynamic> json) {
    return CheckpointData(
      id: json['id'],
      idAgent: json['id_agent'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      dateArrivee: DateTime.parse(json['date_arrivee']),
      dateDepart: json['date_depart'] != null ? DateTime.parse(json['date_depart']) : null,
      adresse: json['adresse'],
      dureeArret: json['duree_arret'],
      typeArret: json['type_arret'],
    );
  }
}