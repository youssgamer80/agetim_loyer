import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'encaissements_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Agent'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final utilisateur = appState.currentUtilisateur; // Changement de agent à utilisateur
          if (utilisateur == null) {
            return const Center(child: Text('Aucun agent connecté'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryBlue,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          utilisateur.nomComplet, // Utilisation de nomComplet
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          utilisateur.rolePrincipal.toUpperCase(), // Utilisation de rolePrincipal
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Divider(height: 30),
                        // Utilisation des champs disponibles sur le modèle Utilisateur
                        _buildInfoRow('ID', utilisateur.idUtilisateur.toString()),
                        // Les champs email/téléphone ne sont pas dans la réponse du login,
                        // on affiche 'N/A' s'ils ne sont pas fournis (comme dans le constructeur par défaut)
                        _buildInfoRow('Email', utilisateur.email ?? 'N/A'),
                        _buildInfoRow('Téléphone', utilisateur.telephone ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      /*Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EncaissementsScreen(),
                        ),
                      );*/
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Mes Encaissements'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: appState.isLoading
                        ? null
                        : () async {
                      await appState.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: appState.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Icon(Icons.logout),
                    label: appState.isLoading
                        ? const Text('Déconnexion en cours...')
                        : const Text('Déconnexion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
