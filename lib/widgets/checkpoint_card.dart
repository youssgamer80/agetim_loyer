import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/checkpoint_data.dart';
import '../theme/app_theme.dart';

class CheckpointCard extends StatelessWidget {
  final CheckpointData checkpoint;

  const CheckpointCard({
    Key? key,
    required this.checkpoint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(checkpoint.typeArret).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(checkpoint.typeArret),
                    color: _getTypeColor(checkpoint.typeArret),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(checkpoint.typeArret),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(checkpoint.dateArrivee),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (checkpoint.dureeArret != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${checkpoint.dureeArret}min',
                      style: const TextStyle(
                        color: AppTheme.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (checkpoint.adresse != null) ...[
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkpoint.adresse!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${checkpoint.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Lng: ${checkpoint.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (checkpoint.dateDepart != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.exit_to_app, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Départ: ${DateFormat('HH:mm').format(checkpoint.dateDepart!)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'maison_locataire':
        return Colors.green;
      case 'pause':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'maison_locataire':
        return Icons.home;
      case 'pause':
        return Icons.coffee;
      default:
        return Icons.place;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'maison_locataire':
        return 'Visite Locataire';
      case 'pause':
        return 'Pause';
      default:
        return 'Arrêt';
    }
  }
}