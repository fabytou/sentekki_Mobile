import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Importations de vos pages
import 'home.dart'; 
import 'auth_state.dart'; 
import 'registration/login.dart';
import 'registration/signup.dart';
import 'SenTekkiColors.dart'; 

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SenTekki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: SenTekkiColors.primary,
        primarySwatch: SenTekkiColors.primaryMaterial, 
      ),
      // 🎯 CORRECTION: Utilise HomeWrapper comme page de démarrage (home)
      // Ce wrapper est conçu pour initialiser AuthState et afficher Home.
      home: const HomeWrapper(), 
      routes: {
        // La page Home n'a plus besoin d'être une route si c'est la page principale.
        // '/home': (_) => const Home(), 
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
      },
    );
  }
}

// --------------------------------------------------------------------------
// 🚦 CLASSE HOMEWRAPPER (Nouveau Wrapper pour la page principale)
// --------------------------------------------------------------------------
// Ce wrapper assure que l'état d'authentification est chargé avant d'afficher
// la page Home, mais affiche toujours Home en premier.
class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  // Indicateur que l'état initial (checkLogin) a été complété
  bool _isAuthChecked = false;

  @override
  void initState() {
    super.initState();
    // Lance la vérification de l'état de connexion au démarrage
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    await authState.checkLogin(); // ⬅️ Attendre la lecture de SharedPreferences
    if (mounted) {
      setState(() {
        _isAuthChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Afficher un indicateur pendant la vérification du token
    if (!_isAuthChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 2. Une fois que la vérification est terminée (quel que soit le résultat),
    // nous affichons la page Home pour permettre la traduction libre.
    return  Home(); 
    
    // Note: L'état de connexion (authState.isLoggedIn) est maintenant 
    // disponible pour la page Home et ses enfants.
  }
}