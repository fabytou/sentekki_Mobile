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

void _translate() async {
  print("Début de la fonction _translate ");
  if (_controller.text.isEmpty) {
    print("Champ texte vide");
    return;
  }

  // ⚠️ Remplace 127.0.0.1 par l’IP de ton PC (ex: 192.168.1.192)
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
        // ✅ utilise la bonne clé envoyée par Django
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
        backgroundColor: SenTekkiColors.primary,
        title: const Text("SenTekki ", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bloc texte source
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur langue source et destination
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _fromLang,
                        items: ["Francais", "Anglais"]
                            .map((lang) =>
                                DropdownMenuItem(value: lang, child: Text(lang)))
                            .toList(),
                        onChanged: (val) => setState(() => _fromLang = val!),
                      ),
                      Icon(Icons.arrow_forward, color: SenTekkiColors.primary),
                      DropdownButton<String>(
                        value: _toLang,
                        items: ["Francais", "Anglais"]
                            .map((lang) =>
                                DropdownMenuItem(value: lang, child: Text(lang)))
                            .toList(),
                        onChanged: (val) => setState(() => _toLang = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Champ texte source
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Écrire le texte à traduire...",
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bouton traduire
            ElevatedButton(
              onPressed: _translate,
              style: ElevatedButton.styleFrom(
                backgroundColor: SenTekkiColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Traduire"),
            ),
            const SizedBox(height: 16),

            // Bloc résultat
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SenTekkiColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_toLang,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(_result,
                                style: const TextStyle(fontSize: 16))),
                        IconButton(
                          onPressed: _clear,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Effacer",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
