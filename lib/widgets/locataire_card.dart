import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LocataireCard extends StatelessWidget {
  final LocataireDetails locataireDetails;
  final VoidCallback onPay;

  const LocataireCard({
    Key? key,
    required this.locataireDetails,
    required this.onPay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInDebt = locataireDetails.montantDu > locataireDetails.logement.loyerMensuel;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nom + Badge retard
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locataireDetails.locataire.nomComplet,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (locataireDetails.locataire.codeLocataire != null)
                        Text(
                          'Code: ${locataireDetails.locataire.codeLocataire}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isInDebt)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EN RETARD',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Téléphone
            if (locataireDetails.locataire.telephone1 != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      locataireDetails.locataire.telephone1!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Info Logement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, size: 20, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locataireDetails.logement.codeLogement,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (locataireDetails.logement.quartier.isNotEmpty &&
                      locataireDetails.logement.quartier != 'N/A') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "QUARTIER: " + locataireDetails.logement.quartier,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Loyer: ${NumberFormat('#,###').format(locataireDetails.logement.loyerMensuel)} FCFA/mois',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Info Propriétaire
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Propriétaire',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          locataireDetails.proprietaire.nomComplet,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (locataireDetails.proprietaire.codeProprietaire.isNotEmpty)
                          Text(
                            'Code: ${locataireDetails.proprietaire.codeProprietaire}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Montant + Bouton payer
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Montant dû:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(locataireDetails.montantDu)} FCFA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isInDebt ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: locataireDetails.montantDu > 0 ? onPay : null,
                  icon: const Icon(Icons.payment),
                  label: const Text('Payer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: locataireDetails.montantDu > 0
                        ? AppTheme.orange
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}