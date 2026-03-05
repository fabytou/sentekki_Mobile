import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'auth_state.dart';
import 'correction.dart';
import 'historique.dart';
import 'api_constants.dart';
import 'custom_app_bar.dart'; // Import indispensable pour l'AppBar et le SideMenu
import 'nav_bar.dart';
import 'CorrectionsPage.dart';
import 'dictionnaire.dart';

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

  // --- GESTION DU CLIC SUR LES PHRASES ---
  void handleSentenceClick(int id, String text) {
    final auth = Provider.of<AuthState>(context, listen: false);
    final String role = (auth.userRole ?? "").toLowerCase().trim();

    bool isAuthorized = role.contains("correcteur") || 
                        role.contains("corrector") || 
                        role == "admin" || 
                        role == "super_admin";

    if (isAuthorized) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seuls les correcteurs peuvent proposer des modifications")),
      );
    }
  }

  // --- LOGIQUE COMMUNE POUR TRAITER LA RÉPONSE API ---
  void _handleApiResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic>? rawSentences = data["output_sentence"];
      
      setState(() {
        currentPopupId = data['id'] ?? 0;
        if (data['input_text'] != null) {
          _textController.text = data['input_text'];
        }
        _sentences = rawSentences?.asMap().entries.map((e) => {
          "id": e.key,
          "text": e.value.toString(),
        }).toList() ?? [];
      });

      final auth = Provider.of<AuthState>(context, listen: false);
      if (auth.isAuthenticated && currentPopupId > 0) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _showRatingPopup(currentPopupId);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur serveur : ${response.statusCode}")),
      );
    }
  }

  // --- APPEL API TRADUCTION TEXTE ---
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
      _handleApiResponse(response);
    } catch (e) {
      debugPrint("Erreur: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE POUR PDF ---
  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      final auth = Provider.of<AuthState>(context, listen: false);
      
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse("${ApiConstants.baseUrl}/api/translate-pdf/"),
        );

        if (result.files.first.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            result.files.first.bytes!,
            filename: result.files.first.name,
          ));
        } else if (result.files.first.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            result.files.first.path!,
          ));
        }

        request.fields['lang_src'] = 'fr';
        request.fields['lang_dest'] = 'en';

        final streamedResponse = await auth.sendMultipartWithAuth(request);
        final response = await http.Response.fromStream(streamedResponse);
        
        _handleApiResponse(response);
        
      } catch (e) {
        debugPrint("Erreur import PDF: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'analyse du document")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- POPUP DE NOTATION ---
  void _showRatingPopup(int translationId) {
    int selectedStars = 0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Notez la qualité", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded, 
                    color: Colors.amber, size: 35
                  ),
                  onPressed: () => setStateDialog(() => selectedStars = index + 1),
                )),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController, 
                decoration: InputDecoration(
                  hintText: "Un commentaire ?",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                )
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Plus tard", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (selectedStars > 0) {
                  final auth = Provider.of<AuthState>(context, listen: false);
                  await auth.postWithAuth("/api/note/", {
                    "translator_id": translationId, 
                    "stars": selectedStars, 
                    "comment": commentController.text
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: const Text("Valider", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    final auth = Provider.of<AuthState>(context, listen: false);
    final String role = (auth.userRole ?? "").toLowerCase().trim();
    final bool isCorrector = role.contains("correcteur") || role.contains("corrector") || role.contains("admin");

    if (index == 0) setState(() => _selectedIndex = 0);
    else if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const DictionaryScreen()));
    else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslationHistoryPage()));
    else if (index == 3) {
      if (isCorrector) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingCorrectionsPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accès réservé aux correcteurs")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    final String role = (auth.userRole ?? "").toLowerCase();
    bool isCorrector = role.contains("correcteur") || role.contains("corrector") || role.contains("admin");

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      // --- APPBAR CORRIGÉE ---
      appBar: const CustomAppBar(currentPageTitle: "Traduire"),
      
      // --- AJOUT DU MENU LATÉRAL (Drawer) ---
      // IMPORTANT : Utiliser endDrawer pour correspondre à la fonction openEndDrawer() de l'AppBar
      endDrawer: const CustomSideMenu(), 
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildLanguageSelector(),
            _buildInputSection(),
            const SizedBox(height: 15),
            _buildTranslateButton(),
            if (_sentences.isNotEmpty) _buildResultSection(isCorrector),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          _langBox("FR", "Français"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFF00A86B), shape: BoxShape.circle),
              child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
            ),
          ),
          _langBox("EN", "English"),
        ],
      ),
    );
  }

  Widget _langBox(String code, String name) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("• TEXTE SOURCE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Text("${_textController.text.length}/2000", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          TextField(
            controller: _textController,
            maxLines: 6,
            onChanged: (v) => setState(() {}),
            decoration: const InputDecoration(
              hintText: "Entrez votre texte ici...",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          const Divider(),
          Row(
            children: [
              _iconAction(Icons.picture_as_pdf_rounded, onTap: _pickPDF),
              _iconAction(Icons.file_upload_outlined),
              _iconAction(Icons.delete_outline_rounded, onTap: () => setState(() => _textController.clear())),
              const Spacer(),
              const Text("SenTekki Translate", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, {VoidCallback? onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF00A86B), size: 22),
    );
  }

  Widget _buildTranslateButton() {
    return InkWell(
      onTap: _isLoading ? null : translateText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00A86B),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF00A86B).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Traduire", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildResultSection(bool isCorrector) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE).withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• TRADUCTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00A86B), letterSpacing: 1.1)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _sentences.map((s) {
              return InkWell(
                onTap: () => handleSentenceClick(s['id'], s['text']),
                borderRadius: BorderRadius.circular(8),
                splashColor: const Color(0xFF00A86B).withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Text(
                    s['text'],
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      height: 1.5,
                      decoration: isCorrector ? TextDecoration.underline : TextDecoration.none,
                      decorationStyle: TextDecorationStyle.dashed,
                      decorationColor: const Color(0xFF00A86B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}