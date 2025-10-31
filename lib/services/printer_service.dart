import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/utilisateur.dart';
import '../services/api_service.dart';

class PrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? _printer;
  bool _isConnected = false;

  // ✅ Ajouter ces helpers
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

  Future<bool> initPrinter() async {
    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      for (var device in devices) {
        if (device.name == "RPP02N") {
          _printer = device;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur init printer: $e');
      return false;
    }
  }

  Future<bool> connectPrinter() async {
    if (_printer == null) {
      print('❌ Aucune imprimante configurée');
      return false;
    }

    try {
      // ✅ FORCER la déconnexion avant chaque tentative de connexion
      if (_isConnected) {
        await _bluetooth.disconnect();
        _isConnected = false;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('🔄 Tentative de connexion à l\'imprimante...');
      await _bluetooth.connect(_printer!);
      _isConnected = true;
      await Future.delayed(const Duration(milliseconds: 1000));
      print('✅ Connexion établie');
      return true;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<bool> _ensureConnection() async {
    // ✅ Tenter la connexion jusqu'à 3 fois avec délai
    for (int attempt = 1; attempt <= 3; attempt++) {
      print('🔄 Tentative de connexion $attempt/3...');

      if (await connectPrinter()) {
        return true;
      }

      if (attempt < 3) {
        print('⏳ Nouvelle tentative dans 2 secondes...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    print('❌ Échec de connexion après 3 tentatives');
    return false;
  }

  Future<bool> printRecu({
    required LocataireDetails locataireDetails,
    required double montantPaye,
    required String numeroRecu,
    required Utilisateur utilisateur,
    List<dynamic>? allocations,
    List<dynamic>? moisRestants,
    double? montantRestantDu,
  }) async {
    try {
      // ✅ FORCER la réinitialisation et connexion au début de chaque impression
      print('🔄 Début impression - Réinitialisation connexion...');

      if (!await _ensureConnection()) {
        print('❌ Impossible d\'établir la connexion Bluetooth');
        return false;
      }

      final apiService = ApiService();
      final codeUnique = await apiService.genererCodeUnique();

      // Logo
      try {
        ByteData logoBytes = await rootBundle.load("assets/logo.png");
        Uint8List values = logoBytes.buffer.asUint8List();
        img.Image? logo = img.decodeImage(values);
        if (logo != null) {
          img.Image resizedLogo = img.copyResize(logo, width: 150);
          Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedLogo));
          _bluetooth.printImageBytes(resizedBytes);
        }
      } catch (e) {
        print("Erreur logo: $e");
      }

      // En-tête
      _bluetooth.printNewLine();
      _bluetooth.printCustom("AGETIM IMMOBILIER", 2, 1);
      _bluetooth.printCustom("Agence de Transactions et de", 0, 1);
      _bluetooth.printCustom("Gestion Immobilieres", 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("================================", 0, 1);
      _bluetooth.printCustom("RECU DE PAIEMENT DE LOYER", 1, 1);
      _bluetooth.printCustom("================================", 0, 1);
      _bluetooth.printNewLine();

      _bluetooth.printCustom("No Reçu: $numeroRecu", 0, 0);
      _bluetooth.printCustom("Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", 0, 0);
      _bluetooth.printCustom("Code: $codeUnique", 0, 0);
      _bluetooth.printNewLine();

      // Agent info
      _bluetooth.printCustom("AGENT COLLECTEUR:", 1, 0);
      _bluetooth.printCustom("${utilisateur.nomComplet}", 0, 0);
      _bluetooth.printCustom("Code: ${utilisateur.codeAgent}", 0, 0);
      if (utilisateur.telephone != null) {
        _bluetooth.printCustom("Tel: ${utilisateur.telephone}", 0, 0);
      }
      _bluetooth.printNewLine();

      // Locataire info
      _bluetooth.printCustom("LOCATAIRE:", 1, 0);
      _bluetooth.printCustom("${locataireDetails.locataire.nomComplet}", 0, 0);
      if (locataireDetails.locataire.telephone1 != null) {
        _bluetooth.printCustom("Tel: ${locataireDetails.locataire.telephone1}", 0, 0);
      }
      _bluetooth.printNewLine();

      // Logement info
      _bluetooth.printCustom("LOGEMENT:", 1, 0);
      _bluetooth.printCustom("Code: ${locataireDetails.logement.codeLogement}", 0, 0);
      _bluetooth.printCustom("Loyer: ${NumberFormat('#,###').format(locataireDetails.logement.loyerMensuel)} FCFA/mois", 0, 0);
      _bluetooth.printNewLine();

      // Propriétaire info
      _bluetooth.printCustom("PROPRIETAIRE:", 1, 0);
      _bluetooth.printCustom("${locataireDetails.proprietaire.nomComplet}", 0, 0);
      _bluetooth.printNewLine();

      // Détails paiement
      _bluetooth.printCustom("--------------------------------", 0, 1);
      _bluetooth.printCustom("DETAILS DU PAIEMENT", 1, 1);
      _bluetooth.printCustom("--------------------------------", 0, 1);
      _bluetooth.printCustom("Montant paye:", 0, 0);
      _bluetooth.printCustom("${NumberFormat('#,###').format(montantPaye)} FCFA", 2, 1);
      _bluetooth.printNewLine();

      // Répartition si disponible
      if (allocations != null && allocations.isNotEmpty) {
        _bluetooth.printCustom("REPARTITION:", 1, 0);
        _bluetooth.printCustom("------------------------", 0, 0);

        for (var alloc in allocations) {
          final mois = _parseInt(alloc['mois']);
          final annee = _parseInt(alloc['annee']);
          final montant = _parseDouble(alloc['montant_couvert']);

          final nomMois = _getNomMois(mois);
          _bluetooth.printCustom(
              "$nomMois $annee: ${NumberFormat('#,###').format(montant)} F",
              0,
              0
          );
        }

        _bluetooth.printNewLine();
      }

      // ✅ AJOUTER : Mois impayés restants
      print('🖨️ Impression mois impayés:');
      print('   moisRestants: $moisRestants');
      print('   montantRestantDu: $montantRestantDu');

      if (moisRestants != null && moisRestants.isNotEmpty) {
        print('   ✅ Affichage des mois impayés');
        _bluetooth.printCustom("MOIS IMPAYES:", 1, 0);
        _bluetooth.printCustom("------------------------", 0, 0);

        for (var mois in moisRestants) {
          final m = _parseInt(mois['mois']);
          final a = _parseInt(mois['annee']);
          final du = _parseDouble(mois['montant_du']);
          final nomMois = _getNomMois(m);
          _bluetooth.printCustom("$nomMois $a: ${NumberFormat('#,###').format(du)} F", 0, 0);
        }
        _bluetooth.printNewLine();
      }

      // ✅ AJOUTER : Solde restant
      if (montantRestantDu != null && montantRestantDu > 0) {
        _bluetooth.printCustom("SOLDE RESTANT:", 1, 0);
        _bluetooth.printCustom("${NumberFormat('#,###').format(montantRestantDu)} FCFA", 2, 2);
      } else if (montantRestantDu != null && montantRestantDu == 0) {
        _bluetooth.printCustom("COMPTE SOLDE", 2, 1);
      }

      _bluetooth.printCustom("--------------------------------", 0, 1);
      _bluetooth.printCustom("TOTAL PAYE: ${NumberFormat('#,###').format(montantPaye)} FCFA", 2, 1);
      _bluetooth.printCustom("--------------------------------", 0, 1);
      _bluetooth.printNewLine();

      // Info SMS
      _bluetooth.printCustom("Un SMS avec les details", 0, 1);
      _bluetooth.printCustom("complets a ete envoye", 0, 1);
      _bluetooth.printCustom("au locataire.", 0, 1);
      _bluetooth.printNewLine();

      // QR Code
      try {
        final qrValidationResult = QrValidator.validate(
          data: codeUnique,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        );

        if (qrValidationResult.status == QrValidationStatus.valid) {
          final qrCode = qrValidationResult.qrCode;
          final painter = QrPainter.withQr(
            qr: qrCode!,
            gapless: true,
            emptyColor: Colors.white,
            color: Colors.black,
          );

          final ui.Image uiImage = await painter.toImage(200);
          final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);

          if (byteData != null) {
            Uint8List pngBytes = byteData.buffer.asUint8List();
            img.Image? qrImg = img.decodeImage(pngBytes);
            if (qrImg != null) {
              img.Image resizedQr = img.copyResize(qrImg, width: 150);
              Uint8List resizedQrBytes = Uint8List.fromList(img.encodePng(resizedQr));
              _bluetooth.printImageBytes(resizedQrBytes);
              _bluetooth.printNewLine();
            }
          }
        }
      } catch (e) {
        print("Erreur QR code: $e");
        _bluetooth.printCustom("Code verification:", 0, 0);
        _bluetooth.printCustom(codeUnique, 0, 1);
      }

      _bluetooth.printNewLine();
      _bluetooth.printCustom("Merci pour votre paiement!", 1, 1);
      _bluetooth.printCustom("Conservez ce recu", 0, 1);
      _bluetooth.printCustom("Scannez le QR pour verification", 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("AGETIM - Votre partenaire immobilier", 0, 1);
      _bluetooth.printNewLine();

      _bluetooth.paperCut();
      await Future.delayed(const Duration(milliseconds: 1500));

      print('✅ Impression terminée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur impression: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      try {
        await _bluetooth.disconnect();
        _isConnected = false;
        print('🔌 Déconnexion imprimante');
      } catch (e) {
        print('❌ Erreur déconnexion: $e');
      }
    }
  }

  String _getNomMois(int mois) {
    const mois_noms = [
      'Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre'
    ];
    return mois >= 1 && mois <= 12 ? mois_noms[mois - 1] : 'Mois $mois';
  }
}