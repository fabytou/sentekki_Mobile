import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_switch/animated_switch.dart';

import '../auth_state.dart';
import '../SenTekkiColors.dart';
import '../home.dart';
import '../correction.dart';
import 'signup.dart';

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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  // Charge les préférences de l'utilisateur au démarrage
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        usernameController.text = prefs.getString('savedUsername') ?? '';
      }
    });
  }

  // Sauvegarde les infos de "Se souvenir de moi"
  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
    if (value) {
      await prefs.setString('savedUsername', usernameController.text.trim());
    } else {
      await prefs.remove('savedUsername');
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _saveRememberMe(_rememberMe);
      final auth = Provider.of<AuthState>(context, listen: false);

      // Tentative de connexion via AuthState
      final success = await auth.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (!success) {
        throw Exception("Identifiants incorrects");
      }

      // --- PERSISTENCE DU TOKEN POUR L'HISTORIQUE ---
      // On s'assure que le token est bien stocké localement après le login
      final prefs = await SharedPreferences.getInstance();
      if (auth.token != null) {
        await prefs.setString('auth_token', auth.token!);
        await prefs.setString('username', auth.userFullName ?? usernameController.text.trim());
      }

      // --- LOGIQUE DE REDIRECTION ---
      final sentence = auth.pendingText;
      final sentenceId = auth.pendingSentenceId;
      final translationId = auth.pendingTranslationId;

      if (sentence != null && sentenceId != null && translationId != null) {
        auth.clearPendingData();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CorrectionScreen(
              sentenceText: sentence,
              sentenceId: sentenceId,
              translationId: translationId,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  Home()),
        );
      }
    } catch (e) {
      String errorMessage = "Connexion impossible. Vérifiez votre réseau.";
      if (e.toString().contains("Identifiants incorrects")) {
        errorMessage = "Nom d'utilisateur ou mot de passe incorrect.";
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erreur", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
            children: [
              // Header avec Image
              Stack(
                children: [
                  Image.asset(
                    'images/images/top_background.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const Positioned(
                    top: 60,
                    left: 25,
                    child: Text(
                      "Bonjour\nConnectez-vous",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    // Champ Username
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Nom d'utilisateur",
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
                    ),
                    const SizedBox(height: 20),
                    // Champ Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      validator: (v) => (v == null || v.length < 4) ? "Mot de passe trop court" : null,
                    ),
                    const SizedBox(height: 15),
                    // Switch Se souvenir de moi
                    Row(
                      children: [
                        AnimatedSwitch(
                          value: _rememberMe,
                          onChanged: (val) => setState(() => _rememberMe = val),
                          colorOff: Colors.grey,
                          colorOn: const Color(0xFF00A86B),
                        ),
                        const SizedBox(width: 10),
                        const Text("Se souvenir de moi", style: TextStyle(color: Colors.grey)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Oublié ?", style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Bouton Principal
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("SE CONNECTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Social Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _socialButton("Google", "images/images/google.png"),
                        _socialButton("Facebook", "images/images/facebook.png"),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Lien Inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas encore de compte ? "),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                          child: const Text("S'inscrire", style: TextStyle(color: Color(0xFF00A86B), fontWeight: FontWeight.bold)),
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

  Widget _socialButton(String label, String asset) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(asset, height: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}