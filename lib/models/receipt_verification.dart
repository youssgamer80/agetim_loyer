import 'encaissement.dart';
import 'utilisateur.dart';

class ReceiptVerification {
  final bool isValid;
  final Encaissement? encaissement;
  final Utilisateur? utilisateur;
  final String message;

  ReceiptVerification({
    required this.isValid,
    this.encaissement,
    this.utilisateur,
    required this.message,
  });

  factory ReceiptVerification.fromJson(Map<String, dynamic> json) {
    return ReceiptVerification(
      isValid: json['is_valid'],
      encaissement: json['encaissement'] != null
          ? Encaissement.fromJson(json['encaissement'])
          : null,
      utilisateur: json['agent'] != null
          ? Utilisateur.fromJson(json['agent'])
          : null,
      message: json['message'],
    );
  }
}