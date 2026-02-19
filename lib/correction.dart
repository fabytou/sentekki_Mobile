import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; 
import 'api_constants.dart';
import 'auth_state.dart';
import 'SenTekkiColors.dart';
import 'registration/login.dart';
// --- PlaceholderScreen (Aucun changement) ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Page $title en construction.",
        style: TextStyle(fontSize: 24, color: SenTekkiColors.primary),
      ),
    );
  }
}

// ------------------------------------------------------------------
// --- CorrectionScreen (MIS À JOUR et bien indenté) ---
// ------------------------------------------------------------------
class CorrectionScreen extends StatefulWidget {
  final String sentenceText;
  final int sentenceId; 
  // 🚨 NOUVELLE PROPRIÉTÉ : L'ID de l'enregistrement de traduction global (Translator.id)
  final int translationId; 

  const CorrectionScreen({
    super.key,
    required this.sentenceText,
    required this.sentenceId,
    required this.translationId, // 🚨 Ajout de l'ID de traduction
  });

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  late TextEditingController _controller;
  bool _isSaving = false;
  
  String _errorMessage = ""; 

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur avec le texte existant (traduit)
    _controller = TextEditingController(text: widget.sentenceText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Retourne toujours à l'écran de traduction (index 0)
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    
    // ... (Logique pour d'autres onglets)
    String title;
    switch (index) {
      case 1:
        title = "Dictionnaire";
        break;
      case 2:
        title = "Historique";
        break;
      case 3:
        title = "Jeux";
        break;
      default:
        return;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Redirection vers l'onglet : $title")),
      );
      Navigator.pop(context); // Retour à la page précédente (Home)
    }
  }
  
  void _copyOriginalText() {
    Clipboard.setData(ClipboardData(text: widget.sentenceText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Phrase originale copiée.")),
    );
  }

  // ----------------------------------------------------
  // Logique de Sauvegarde (CORRIGÉE pour correspondre à Django)
  // ----------------------------------------------------
  Future<void> _saveCorrection() async {
    final correctionText = _controller.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = "";
    });

    // 1. VÉRIFICATION CRITIQUE DE L'ID DE TRADUCTION
    if (widget.translationId <= 0) { // 🚨 Utilise translationId
      setState(() {
        _errorMessage = "ID de traduction invalide (ID: ${widget.translationId}). Impossible d'enregistrer.";
        _isSaving = false;
      });
      return;
    }

    if (correctionText.isEmpty) {
      setState(() {
        _errorMessage = "La correction ne peut pas être vide.";
        _isSaving = false;
      });
      return;
    }
    
    if (correctionText == widget.sentenceText.trim()) {
      setState(() {
        _errorMessage = "La correction proposée est identique à l'originale.";
        _isSaving = false;
      });
      return;
    }

    final authState = Provider.of<AuthState>(context, listen: false);

    // 2. VÉRIFICATION DE L'AUTHENTIFICATION 
    if (!authState.isAuthenticated) {
      setState(() {
        _errorMessage = "Veuillez vous reconnecter pour enregistrer cette correction.";
        _isSaving = false;
      });
      return;
    }
    
    const endpoint = ApiConstants.addCorrectionEndpoint; 
    
    try {
      // 🚨 CORRECTION CLÉ API : Utilise `widget.translationId` comme `translator_id`
      final bodyData = {
        "translator_id": widget.translationId, // 🎯 Utilise l'ID de la TRADUCTION globale
        "phrase_source": widget.sentenceText,  // Texte original de la phrase
        "phrase_corrigee": correctionText,     // Texte corrigé
      };

      final response = await authState.postWithAuth(
        endpoint,
        bodyData,
        retry: true,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Correction enregistrée avec succès ! Merci pour votre contribution. 🎉"),
              backgroundColor: SenTekkiColors.primary,
            ),
          );
          
          // Vider les données en attente et de dernière traduction après succès
          authState.clearPendingData();
          authState.clearLastTranslationData();
          
          Navigator.pop(context); // Retour à la page précédente (Home)
        }
      } else {
        // Gestion détaillée des erreurs API
        String apiError = response.reasonPhrase ?? "Erreur inconnue";
        try {
          final error = jsonDecode(response.body);
          apiError = error['error'] ?? error['detail'] ?? error.toString();
        } catch (_) {
          // Afficher une partie du corps si le JSON est invalide
          apiError = "Erreur API (${response.statusCode}): ${response.body.substring(0, response.body.length < 50 ? response.body.length : 50)}...";
        }
        
        if (mounted) {
          setState(() {
            _errorMessage = apiError;
          });
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
            _errorMessage = "Échec de la requête réseau: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ----------------------------------------------------
  // Widget build (UI)
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SenTekkiColors.background,
      appBar: AppBar(
        backgroundColor: SenTekkiColors.primary,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              "Correction de Phrase",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phrase à corriger (affichage de l'ID de traduction)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: SenTekkiColors.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 💡 Afficher l'ID de traduction pour le débogage
                    "Phrase à corriger (ID de Traduction: ${widget.translationId} | Index: ${widget.sentenceId}) :", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: SenTekkiColors.primary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Ajout d'un bouton de copie pour l'ergonomie
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.sentenceText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                        onPressed: _copyOriginalText,
                        tooltip: "Copier le texte original",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Champ de correction
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Saisissez la correction ici...",
                  labelText: "Votre meilleure correction",
                  labelStyle: TextStyle(color: SenTekkiColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(15.0),
                ),
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 25),
            
            // Bouton Enregistrer
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCorrection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SenTekkiColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ENREGISTRER LA CORRECTION",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Affichage du message d'erreur
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Erreur : $_errorMessage",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar (inchangée)
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Traduction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Dictionnaire',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset_outlined),
            label: 'Jeux',
          ),
        ],
        currentIndex: 0, 
        selectedItemColor: SenTekkiColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}