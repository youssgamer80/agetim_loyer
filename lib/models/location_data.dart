class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? adresse;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.adresse,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'adresse': adresse,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      adresse: json['adresse'],
    );
  }
}