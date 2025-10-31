import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/receipt_verification.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.lightBlue.withOpacity(0.1),
            child: const Text(
              'Pointez la caméra vers le QR code du reçu à vérifier',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppTheme.orange,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text(
                'Alignez le QR code dans le cadre',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String code) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiService();
      final verification = await apiService.verifierRecu(code);

      controller?.pauseCamera();

      if (verification.isValid && verification.encaissement != null) {
        _showVerificationDialog(verification);
      } else {
        _showErrorDialog(verification.message);
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la vérification: $e');
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _showVerificationDialog(ReceiptVerification verification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reçu Authentique',
                style: TextStyle(color: Colors.green, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le reçu avec le code ${verification.encaissement!.codeUnique} est authentique et prouve que le locataire a payé son loyer.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voici les détails de l\'encaissement:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Reçu N°', verification.encaissement!.numeroRecu),
            _buildDetailRow('Date', DateFormat('dd/MM/yyyy HH:mm').format(verification.encaissement!.datePaiement)),
            _buildDetailRow('Locataire', verification.encaissement!.nomLocataire),
            _buildDetailRow('Logement', verification.encaissement!.codeLogement),
            _buildDetailRow('Montant', '${NumberFormat('#,###').format(verification.encaissement!.montantPaye)} FCFA'),
            _buildDetailRow('Mode', verification.encaissement!.modePaiement.toUpperCase()),
            if (verification.utilisateur != null)
              _buildDetailRow('Agent', verification.utilisateur!.nomComplet),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller?.resumeCamera();
            },
            child: const Text('Scanner un autre'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Reçu Non Valide', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller?.resumeCamera();
            },
            child: const Text('Réessayer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}