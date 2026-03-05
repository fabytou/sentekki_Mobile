import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTATIONS DES PAGES ---
import 'home.dart'; 
import 'auth_state.dart'; 
import 'registration/login.dart';
import 'registration/signup.dart';
import 'dictionnaire.dart';
import 'historique.dart'; // Assure-toi que le fichier existe
import 'CorrectionsPage.dart'; // Assure-toi que le fichier existe
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
        fontFamily: 'Roboto', 
      ),
      
      home: const HomeWrapper(), 

      // --- TABLE DES ROUTES (Le GPS de l'application) ---
      // Les noms ici doivent être IDENTIQUES à ceux dans nav_bar.dart
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/translation': (_) => const Home(), 
        '/dictionary': (_) => const DictionaryScreen(),
        '/history': (_) => const TranslationHistoryPage(), 
        '/corrections': (_) => const PendingCorrectionsPage(),
      },
    );
  }
}

// 🚦 CLASSE HOMEWRAPPER (Vérification de l'auth au démarrage)
class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  bool _isAuthChecked = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    await authState.checkLogin(); 
    if (mounted) {
      setState(() {
        _isAuthChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthChecked) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
          ),
        ),
      );
    }
    return const Home(); 
  }
}