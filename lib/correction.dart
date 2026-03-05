import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'api_constants.dart';
import 'auth_state.dart';
import 'SenTekkiColors.dart';

// --- CorrectionScreen ---
class CorrectionScreen extends StatefulWidget {
  final String sentenceText;
  final int sentenceId;
  final int translationId;

  const CorrectionScreen({
    super.key,
    required this.sentenceText,
    required this.sentenceId,
    required this.translationId,
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
    _controller = TextEditingController(text: widget.sentenceText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyOriginalText() {
    Clipboard.setData(ClipboardData(text: widget.sentenceText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Texte copié dans le presse-papier"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveCorrection() async {
    final correctionText = _controller.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = "";
    });

    if (widget.translationId <= 0) {
      setState(() {
        _errorMessage = "ID de traduction invalide.";
        _isSaving = false;
      });
      return;
    }

    if (correctionText.isEmpty) {
      setState(() {
        _errorMessage = "Le champ de correction est vide.";
        _isSaving = false;
      });
      return;
    }

    final authState = Provider.of<AuthState>(context, listen: false);

    try {
      final bodyData = {
        "translator_id": widget.translationId,
        "phrase_source": widget.sentenceText,
        "phrase_corrigee": correctionText,
      };

      final response = await authState.postWithAuth(
        ApiConstants.addCorrectionEndpoint,
        bodyData,
        retry: true,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Correction enregistrée avec succès ! 🎉"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // TRÈS IMPORTANT : On renvoie 'true' pour que la page précédente se rafraîchisse
          Navigator.pop(context, true); 
        }
      } else {
        String apiError = "Erreur serveur (${response.statusCode})";
        try {
          final error = jsonDecode(utf8.decode(response.bodyBytes));
          apiError = error['error'] ?? error['detail'] ?? apiError;
        } catch (_) {}
        if (mounted) setState(() => _errorMessage = apiError);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Erreur réseau : $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Apporter une correction", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: SenTekkiColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION TEXTE ORIGINAL ---
            const Text(
              "TEXTE ORIGINAL",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.sentenceText,
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 20),
                    onPressed: _copyOriginalText,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // --- SECTION CHAMP DE CORRECTION ---
            const Text(
              "VOTRE CORRECTION",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Saisissez la version correcte ici...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: SenTekkiColors.primary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: SenTekkiColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- MESSAGE D'ERREUR ---
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),

            // --- BOUTON VALIDER ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCorrection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SenTekkiColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ENREGISTRER LA MODIFICATION",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}