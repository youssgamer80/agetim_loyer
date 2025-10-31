import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min, // Pour que la Row ne prenne que l'espace nécessaire
                            children: [
                              const Text(
                                'AGETIM LOYER APP',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.apartment,
                                color: AppTheme.primaryBlue,
                                size: 30,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre nom d\'utilisateur';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          Consumer<AppState>(
                            builder: (context, appState, child) {
                              return Column(
                                children: [
                                  if (appState.error.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Text(
                                        appState.error,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    height:50,
                                    child: ElevatedButton(
                                      onPressed: appState.isLoading ? null : _login,
                                      child: appState.isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : const Text('Se connecter'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final appState = Provider.of<AppState>(context, listen: false);
      final success = await appState.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        // Naviguer vers l'écran d'accueil après une connexion réussie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
      // Si la connexion échoue, le message d'erreur est géré par le Consumer dans le build.
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
