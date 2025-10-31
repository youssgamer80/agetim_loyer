/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/encaissement.dart';
import '../widgets/encaissement_card.dart';

class EncaissementsScreen extends StatefulWidget {
  @override
  _EncaissementsScreenState createState() => _EncaissementsScreenState();
}

class _EncaissementsScreenState extends State<EncaissementsScreen> {
  List<Encaissement> _encaissements = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadEncaissements();
  }

  Future<void> _loadEncaissements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.currentUtilisateur != null) {
        final encaissements = await _apiService.getEncaissementsForAgent(
          appState.currentUtilisateur!.idUtilisateur,
        );
        setState(() {
          _encaissements = encaissements;
        });
      }
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
    final totalEncaisse = _encaissements.fold<double>(
      0,
          (sum, encaissement) => sum + encaissement.montantPaye,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Encaissements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEncaissements,
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
                            Icons.receipt,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_encaissements.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Paiements',
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
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${NumberFormat('#,###').format(totalEncaisse)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'FCFA Total',
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
                : _encaissements.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun encaissement trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadEncaissements,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _encaissements.length,
                itemBuilder: (context, index) {
                  final encaissement = _encaissements[index];
                  return EncaissementCard(encaissement: encaissement);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/