import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_state.dart';
import '../SenTekkiColors.dart';
import '../home.dart';
import '../correction.dart';
import 'signup.dart';
// ignore: depend_on_referenced_packages
import 'package:animated_switch/animated_switch.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Nécessaire pour gérer 'Se souvenir de moi'

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false; // 🟢 Ajout de la variable d'état pour le switch

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  // 🟢 Méthode pour charger l'état de 'Se souvenir de moi'
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        // Charger les derniers identifiants si "Se souvenir de moi" est actif
        usernameController.text = prefs.getString('savedUsername') ?? '';
        // Note: Il n'est généralement pas recommandé de sauvegarder le mot de passe
      }
    });
  }

  // 🟢 Méthode pour sauvegarder l'état et les données si nécessaire
  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
    if (value) {
      await prefs.setString('savedUsername', usernameController.text.trim());
      // On efface le mot de passe s'il n'est pas sauvegardé (recommandé)
    } else {
      await prefs.remove('savedUsername');
      await prefs.remove('savedPassword');
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // 🟢 Sauvegarde de l'état du switch avant la tentative de connexion
      await _saveRememberMe(_rememberMe);

      final auth = Provider.of<AuthState>(context, listen: false);

      // 🟢 Vérification explicite du succès
      final success = await auth.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (!success) {
        // Si login retourne false (Identifiants incorrects), lever une exception personnalisée
        throw Exception("Identifiants incorrects");
      }

      // --- Logique de redirection après succès ---

      // Récupération des données en attente
      final sentence = auth.pendingText;
      final sentenceId = auth.pendingSentenceId;
      // 🎯 CORRECTION : Récupérer le translationId depuis AuthState
      final translationId = auth.pendingTranslationId;

      if (sentence != null && sentenceId != null && translationId != null) { // 🎯 Vérification du translationId

        // 🟢 Utilisation de clearPendingData() pour la clarté
        auth.clearPendingData();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CorrectionScreen(
              sentenceText: sentence,
              sentenceId: sentenceId,
              // 🟢 Correction appliquée ici
              translationId: translationId,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  Home()),
        );
      }
    } catch (e) {
      // 🟢 Gestion des erreurs :
      String errorMessage = "Connexion impossible. Veuillez vérifier votre réseau.";
      if (e.toString().contains("Identifiants incorrects")) {
        errorMessage = "Nom d'utilisateur ou mot de passe incorrect.";
      }
      _showErrorDialog(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erreur de connexion", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SenTekkiColors.background,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.asset(
                    'images/images/top_background.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const Positioned(
                    top: 50,
                    left: 20,
                    child: Text(
                      "Bonjour\nConnectez-vous",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Nom d'utilisateur
                    TextFormField(
                      controller: usernameController,
                      validator: (value) => (value == null || value.isEmpty)
                          ? "Veuillez entrer votre nom d'utilisateur"
                          : null,
                      decoration: InputDecoration(
                        labelText: "Nom d'utilisateur",
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: SenTekkiColors.lightGray,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Mot de passe
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez entrer votre mot de passe";
                        }
                        // La validation de longueur est parfois faite côté backend, mais peut rester ici
                        if (value.length < 6) {
                          return "Mot de passe trop court (min. 6 caractères)";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: SenTekkiColors.lightGray,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Se souvenir et mot de passe oublié
                    Row(
                      children: [
                        // 🟢 Implémentation du Switch
                        AnimatedSwitch(
                            value: _rememberMe,
                            onChanged: (newValue) {
                              setState(() {
                                _rememberMe = newValue;
                              });
                            },
                            colorOff: const Color(0xffA09F99),
                            colorOn: const Color.fromARGB(255, 1, 58, 1)),
                        const SizedBox(width: 5),
                        const Text("Se souvenir de moi",
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const Spacer(),
                        const Text("Mot de passe oublié ?",
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bouton connexion
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _handleLogin(context),
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        label: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "SE CONNECTER",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 6, 61, 29),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Boutons sociaux
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _socialButton("Facebook", "images/images/facebook.png",
                            const Color.fromRGBO(10, 146, 71, 1)),
                        _socialButton("Google", "images/images/google.png",
                            const Color.fromARGB(255, 17, 155, 29)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Lien inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Vous n’avez pas de compte ?"),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen()),
                          ),
                          child: Text(
                            "S'inscrire",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 14, 66, 34),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String label, String asset, Color color) {
    return Container(
      height: 50,
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(asset, width: 30, height: 30),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}