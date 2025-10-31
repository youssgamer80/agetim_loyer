import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../providers/app_state.dart';

class PaymentDialog extends StatefulWidget {
  final LocataireDetails locataireDetails;
  final PrinterService printerService;
  final VoidCallback onSuccess;

  const PaymentDialog({
    Key? key,
    required this.locataireDetails,
    required this.printerService,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _montantController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String _modePaiement = 'espèces';

  @override
  void initState() {
    super.initState();
    _montantController.text = widget.locataireDetails.montantDu.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    print(widget.locataireDetails.locataire.codeLocataire);
    return AlertDialog(
      title: const Text('Enregistrer un paiement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info locataire
              Text(
                'Locataire: ${widget.locataireDetails.locataire.nomComplet}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Logement: ${widget.locataireDetails.logement.codeLogement}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Montant dû: ${NumberFormat('#,###').format(widget.locataireDetails.montantDu)} FCFA',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Montant payé
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant reçu (FCFA)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Montant requis';
                  final montant = double.tryParse(value!);
                  if (montant == null || montant <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mode de paiement
              DropdownButtonFormField<String>(
                value: _modePaiement,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'espèces', child: Text('Espèces')),
                  DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'virement', child: Text('Virement')),
                  DropdownMenuItem(value: 'chèque', child: Text('Chèque')),
                ],
                onChanged: (value) {
                  setState(() => _modePaiement = value!);
                },
              ),

              // Info SMS automatique
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sms, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SMS envoyé automatiquement au locataire',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _showConfirmationDialog,
          child: _isProcessing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Continuer'),
        ),
      ],
    );
  }

  void _showConfirmationDialog() {
    if (_formKey.currentState?.validate() ?? false) {
      final montant = double.parse(_montantController.text);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmez-vous avoir reçu ce montant du locataire ?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Montant: ${NumberFormat('#,###').format(montant)} FCFA'),
              Text('Mode: ${_modePaiement.toUpperCase()}'),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Le reçu ne sera généré qu\'une seule fois',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment(montant);
              },
              child: const Text('Confirmer & Imprimer'),
            ),
          ],
        ),
      );
    }
  }

  /*void _processPayment(double montant) async {
    setState(() => _isProcessing = true);

    try {
      final apiService = ApiService();
      final numeroRecu = await apiService.genererNumeroRecu();
      final appState = Provider.of<AppState>(context, listen: false);

      // 1. Enregistrer l'encaissement (SMS automatique)
      final result = await appState.enregistrerPaiement(
        locataireDetails: widget.locataireDetails,
        montantPaye: montant,
        numeroRecu: numeroRecu,
        modePaiement: _modePaiement,
      );

      // ✅ AJOUTER ces logs
      print('📊 Résultat encaissement:');
      print('   Success: ${result['success']}');
      print('   Allocations: ${result['allocations']}');
      print('   Mois restants: ${result['mois_restants']}');
      print('   Montant restant: ${result['montant_restant_du']}');

      if (result['success'] != true) {
        throw Exception('Erreur enregistrement du paiement');
      }

      // 2. Imprimer le reçu AVEC les allocations
      final printSuccess = await widget.printerService.printRecu(
        locataireDetails: widget.locataireDetails,
        montantPaye: montant,
        numeroRecu: numeroRecu,
        utilisateur: appState.currentUtilisateur!,
        allocations: result['allocations'], // ✅ Passer les allocations
        moisRestants: result['mois_restants'],  // ✅ AJOUTER
        montantRestantDu: result['montant_restant_du']?.toDouble(),  // ✅ AJOUTER
      );

      if (!printSuccess) {
        print('⚠️ Erreur impression, mais paiement enregistré');
      }

      Navigator.pop(context);
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['sms_envoye'] == true
                  ? '✅ Paiement enregistré. Reçu imprimé et SMS envoyé.'
                  : '✅ Paiement enregistré et reçu imprimé.'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }*/
  void _processPayment(double montant) async {
    setState(() => _isProcessing = true);

    // Variables pour stocker le résultat de la simulation et le numéro de reçu
    Map<String, dynamic>? simulationResult;
    String? numeroRecu;
    bool printSuccess = false;

    try {
      final apiService = ApiService();
      final appState = Provider.of<AppState>(context, listen: false);
      final utilisateurId = appState.currentUtilisateur?.id;
      final agentId = utilisateurId; // Utiliser l'ID de l'utilisateur comme agent

      if (agentId == null) {
        throw Exception("ID de l'agent utilisateur non trouvé.");
      }

      // 1. Générer le numéro de reçu à l'avance
      numeroRecu = await apiService.genererNumeroRecu();

      // 2. SIMULER l'encaissement pour obtenir les détails d'allocation
      simulationResult = await apiService.simulateEncaissement(
        contratId: widget.locataireDetails.contratId,
        montantTotal: montant,
        agentId: agentId,
        modePaiement: _modePaiement,
        referencePaiement: null, // À ajuster si vous avez un champ pour la référence
        commentaire: 'Paiement loyer', // À ajuster si vous avez un champ commentaire
      );

      if (simulationResult['success'] != true) {
        throw Exception('Erreur de simulation du paiement');
      }

      // ✅ AJOUTER ces logs
      print('📊 Résultat simulation:');
      print('   Success: ${simulationResult!['success']}');
      print('   Allocations: ${simulationResult['allocations']}');
      print('   Mois restants: ${simulationResult['mois_restants']}');
      print('   Montant restant: ${simulationResult['montant_restant_du']}');

      // 3. Imprimer le reçu AVEC les allocations de la simulation
      printSuccess = await widget.printerService.printRecu(
        locataireDetails: widget.locataireDetails,
        montantPaye: montant,
        numeroRecu: numeroRecu!,
        utilisateur: appState.currentUtilisateur!,
        allocations: simulationResult['allocations'], // ✅ Détails de la simulation
        moisRestants: simulationResult['mois_restants'],
        montantRestantDu: simulationResult['montant_restant_du']?.toDouble(),
      );

      if (!printSuccess) {
        // ⚠️ L'impression a échoué. On ne procède PAS à l'enregistrement.
        _showError('⚠️ Erreur d\'impression du reçu. Veuillez réessayer ou contacter le support. L\'encaissement n\'a PAS été enregistré.');
        return; // Sortie de la fonction sans enregistrer
      }

      // 4. L'impression a réussi : ENREGISTRER l'encaissement dans la base de données
      final result = await appState.enregistrerPaiement(
        locataireDetails: widget.locataireDetails,
        montantPaye: montant,
        numeroRecu: numeroRecu,
        modePaiement: _modePaiement,
      );

      if (result['success'] != true) {
        throw Exception('Erreur enregistrement du paiement après impression réussie');
      }

      // 5. Finalisation
      Navigator.pop(context); // Fermer le PaymentDialog
      widget.onSuccess(); // Actualiser la page principale

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['sms_envoye'] == true
                  ? '✅ Paiement enregistré. Reçu imprimé et SMS envoyé.'
                  : '✅ Paiement enregistré et reçu imprimé (sans SMS).'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      _showError('Erreur critique: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }
}