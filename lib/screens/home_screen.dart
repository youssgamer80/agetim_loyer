import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/printer_service.dart';
import '../services/api_service.dart';
import '../widgets/locataire_card.dart';
import '../widgets/payment_dialog.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'historique_deplacements_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrinterService _printerService = PrinterService();
  final TextEditingController _searchController = TextEditingController();
  bool _printerReady = false;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    final ready = await _printerService.initPrinter();
    setState(() {
      _printerReady = ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collecte de Loyers'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close : Icons.search,
            ),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  Provider.of<AppState>(context, listen: false).clearFilters();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _printerReady ? Icons.print : Icons.print_disabled,
              color: _printerReady ? Colors.white : Colors.red,
            ),
            onPressed: _initPrinter,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner),
                    SizedBox(width: 8),
                    Text('Vérifier un reçu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'historique',
                child: Row(
                  children: [
                    Icon(Icons.map),
                    SizedBox(width: 8),
                    Text('Historique GPS'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Actualiser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              } else if (value == 'verify') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRScannerScreen()),
                );
              } else if (value == 'historique') {
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoriqueDeplacementsScreen()),
                );*/
              } else if (value == 'refresh') {
                Provider.of<AppState>(context, listen: false).clearFilters();
              } else if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.currentUtilisateur == null) {
            return const Center(child: Text('Non connecté'));
          }

          return Column(
            children: [
              // En-tête avec info utilisateur
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.lightBlue.withOpacity(0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agent: ${appState.currentUtilisateur!.nomComplet}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Role: ${appState.currentUtilisateur!.codeAgent}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (appState.paginationInfo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${appState.paginationInfo!.totalCount} locataires',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appState.isLocationServiceActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: appState.isLocationServiceActive
                              ? Colors.green
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            appState.isLocationServiceActive
                                ? Icons.gps_fixed
                                : Icons.gps_off,
                            color: appState.isLocationServiceActive
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GPS: ${appState.locationStatus}',
                            style: TextStyle(
                              color: appState.isLocationServiceActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (appState.currentLocation != null) ...[
                            const Spacer(),
                            Text(
                              'Lat: ${appState.currentLocation!.latitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lng: ${appState.currentLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Barre de recherche
              if (_showSearchBar)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Nom, code ou téléphone...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    appState.clearFilters();
                                  },
                                )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  appState.searchLocataires(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: appState.isLoading
                                ? null
                                : () {
                              if (_searchController.text.isNotEmpty) {
                                appState.searchLocataires(_searchController.text);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: appState.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Icon(Icons.search),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (appState.searchQuery.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.filter_alt, size: 18),
                              label: Text('Recherche: ${appState.searchQuery}'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                _searchController.clear();
                                appState.clearFilters();
                              },
                            ),
                          const Spacer(),
                          if (appState.paginationInfo != null)
                            Text(
                              '${appState.locataires.length} résultat(s)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Liste des locataires
              Expanded(
                child: appState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : appState.error.isNotEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appState.error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => appState.clearFilters(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
                    : appState.locataires.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucun locataire trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                    : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => appState.clearFilters(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: appState.locataires.length,
                          itemBuilder: (context, index) {
                            final locataireDetails = appState.locataires[index];
                            return LocataireCard(
                              locataireDetails: locataireDetails,
                              onPay: () => _showPaymentDialog(locataireDetails),
                            );
                          },
                        ),
                      ),
                    ),

                    // Barre de pagination
                    if (appState.paginationInfo != null &&
                        appState.paginationInfo!.totalPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bouton Page précédente
                            ElevatedButton.icon(
                              onPressed: appState.paginationInfo!.hasPreviousPage
                                  ? () => appState.loadPreviousPage()
                                  : null,
                              icon: const Icon(Icons.chevron_left, size: 20),
                              label: const Text('Précédent'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),

                            // Indicateur de page
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Page ${appState.currentPage} / ${appState.paginationInfo!.totalPages}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            // Bouton Page suivante
                            ElevatedButton.icon(
                              onPressed: appState.paginationInfo!.hasNextPage
                                  ? () => appState.loadNextPage()
                                  : null,
                              icon: const Icon(Icons.chevron_right, size: 20),
                              label: const Text('Suivant'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentDialog(LocataireDetails locataireDetails) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        locataireDetails: locataireDetails,
        printerService: _printerService,
        onSuccess: () {
          Provider.of<AppState>(context, listen: false).clearFilters();
        },
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AppState>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}