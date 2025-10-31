/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/checkpoint_data.dart';
import '../widgets/checkpoint_card.dart';

class HistoriqueDeplacementsScreen extends StatefulWidget {
  @override
  _HistoriqueDeplacementsScreenState createState() => _HistoriqueDeplacementsScreenState();
}

class _HistoriqueDeplacementsScreenState extends State<HistoriqueDeplacementsScreen> {
  List<CheckpointData> _checkpoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final historique = await appState.getHistoriqueDeplacements();
      setState(() {
        _checkpoints = historique;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique GPS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistorique,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.lightBlue.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: AppTheme.primaryBlue,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_checkpoints.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Arrêts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: AppTheme.orange,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_calculateTotalDuration()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Temps total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _checkpoints.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun historique trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadHistorique,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _checkpoints.length,
                itemBuilder: (context, index) {
                  final checkpoint = _checkpoints[index];
                  return CheckpointCard(checkpoint: checkpoint);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalDuration() {
    int totalMinutes = 0;
    for (final checkpoint in _checkpoints) {
      if (checkpoint.dureeArret != null) {
        totalMinutes += checkpoint.dureeArret!;
      }
    }

    if (totalMinutes < 60) {
      return '${totalMinutes}min';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '${hours}h${minutes}min';
    }
  }
}*/