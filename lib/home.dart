import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'auth_state.dart';
import 'correction.dart';
import 'historique.dart';
import 'api_constants.dart';
import 'custom_app_bar.dart';
import 'nav_bar.dart';
import 'CorrectionsPage.dart'; 

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: const PageStorageKey('home_page'));

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> _sentences = [];
  bool _isLoading = false;
  int currentPopupId = 0;
  int _selectedIndex = 0;

  void handleSentenceClick(int id, String text) {
    final auth = Provider.of<AuthState>(context, listen: false);
    final String role = (auth.userRole ?? "").toLowerCase().trim();

    if (role == "corrector" || role == "correcteur" || role == "admin" || role == "super_admin") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CorrectionScreen(
            sentenceText: text,
            sentenceId: id,
            translationId: currentPopupId,
          ),
        ),
      );
    }
  }

  // --- CORRECTION DE LA NAVIGATION ICI ---
  void _onItemTapped(int index) {
    final auth = Provider.of<AuthState>(context, listen: false);
    final String role = (auth.userRole ?? "").toLowerCase().trim();
    final bool isCorrector = role == "corrector" || role == "correcteur" || role == "admin" || role == "super_admin";

    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    if (index == 2) { // Historique
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TranslationHistoryPage()),
      );
      return;
    }

    if (index == 3) { // Correction (Nouvelle logique ajoutée)
      if (isCorrector) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PendingCorrectionsPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Accès réservé aux correcteurs"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Si tu ajoutes la page Dico plus tard, ce sera l'index 1
    if (index == 1) {
       setState(() => _selectedIndex = 1);
       // Navigator.push... vers Dico
    }
  }

  // --- LOGIQUE DE TRADUCTION ---
  Future<void> translateText() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthState>(context, listen: false);

    try {
      final bodyData = {
        "input_text": _textController.text,
        "lang_src": 'fr',
        "lang_dest": 'en',
      };

      http.Response response;
      if (auth.isAuthenticated) {
        response = await auth.postWithAuth(ApiConstants.translateEndpoint, bodyData);
      } else {
        response = await http.post(
          Uri.parse("${ApiConstants.baseUrl}${ApiConstants.translateEndpoint}"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(bodyData),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic>? rawSentences = data["output_sentence"];
        setState(() {
          currentPopupId = data['id'] ?? 0;
          _sentences = rawSentences?.asMap().entries.map((e) => {
            "id": e.key,
            "text": e.value.toString(),
          }).toList() ?? [];
        });

        if (auth.isAuthenticated && currentPopupId > 0) {
          Future.delayed(const Duration(milliseconds: 600), () {
            _showRatingPopup(currentPopupId);
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur Traduction: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ENVOI DE LA NOTE ---
  Future<void> _submitRating(int translationId, int stars, String comment) async {
    final auth = Provider.of<AuthState>(context, listen: false);
    try {
      final response = await auth.postWithAuth("/api/note/", {
        "translator_id": translationId, 
        "stars": stars,                 
        "comment": comment,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note enregistrée !"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur Note: $e");
    }
  }

  void _showRatingPopup(int translationId) {
    int selectedStars = 0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Notez la traduction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedStars ? Icons.star : Icons.star_border, 
                    color: Colors.orange, size: 30
                  ),
                  onPressed: () => setStateDialog(() => selectedStars = index + 1),
                )),
              ),
              TextField(
                controller: commentController, 
                decoration: const InputDecoration(hintText: "Commentaire (optionnel)")
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                if (selectedStars > 0) {
                  await _submitRating(translationId, selectedStars, commentController.text);
                }
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
              child: const Text("Voter", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    final String role = (auth.userRole ?? "").toLowerCase().trim();
    bool canCorrect = role == "corrector" || role == "correcteur" || role == "admin" || role == "super_admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: const CustomAppBar(currentPageTitle: "SenTekki"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputCard(),
            const SizedBox(height: 20),
            if (_sentences.isNotEmpty) _buildResultCard(canCorrect),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE9F0F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Saisissez votre texte...",
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Français ➔ Anglais", 
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : translateText,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text("Traduire", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(bool canCorrect) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9F0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TRADUCTION", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
              if (currentPopupId > 0)
                IconButton(
                  icon: const Icon(Icons.star_outline, size: 18, color: Colors.orange),
                  onPressed: () => _showRatingPopup(currentPopupId),
                )
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _sentences.map((s) => InkWell(
              onTap: () => handleSentenceClick(s['id'], s['text']),
              child: Text(
                s['text'], 
                style: TextStyle(
                  fontSize: 18, 
                  color: Colors.black87,
                  decoration: canCorrect ? TextDecoration.underline : TextDecoration.none,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: Colors.green
                )
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}