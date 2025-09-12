import 'package:flutter/material.dart';
import 'SenTekkiColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
  
}

class _HomeState extends State<Home> {
  final TextEditingController _controller = TextEditingController();
  String _result = "";
  String _fromLang = "fr"; // valeur par défaut
  String _toLang = "en";   // valeur par défaut

  Future<void> _translate() async {
    print("Début de la fonction _translate ");
    if (_controller.text.isEmpty) {
      print("Champ texte vide");
      return;
    }

    // ⚠️ Mets l’IP locale de ton PC si tu testes sur mobile
    final url = Uri.parse("http://127.0.0.1:8000/api/translate/");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": _controller.text,
          "src": _fromLang,
          "dest": _toLang,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // ✅ utilise la bonne clé de ton backend Django
          _result = data["translated_text"] ?? "Aucune traduction reçue";
        });
      } else {
        setState(() {
          _result = "Erreur API: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Erreur: $e";
      });
      print("Erreur lors de l'appel API: $e");
    }
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _result = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Traducteur FR ⇄ EN"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ de saisie
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Texte en français",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _translate,
                  child: const Text("Traduire"),
                ),
                ElevatedButton(
                  onPressed: _clear,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Effacer"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Résultat
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result.isEmpty ? "Résultat de la traduction..." : _result,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
