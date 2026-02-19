import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';

class HistoriqueCompletPage extends StatefulWidget {
  const HistoriqueCompletPage({Key? key}) : super(key: key);

  @override
  State<HistoriqueCompletPage> createState() => _HistoriqueCompletPageState();
}

class _HistoriqueCompletPageState extends State<HistoriqueCompletPage> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _fetchFullHistory);
  }

  Future<void> _fetchFullHistory() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.historyAllEndpoint}"),
        headers: {
          "Accept": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          history = data["results"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur serveur : ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau : $e")),
      );
    }
  }

  Widget _buildStars(double average) {
    int fullStars = average.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  Widget _buildItem(item) {
    String user = item["user"] ?? "Anonyme";
    String createdAt = item["created_at"] ?? "";
    double averageStars = (item["average_stars"] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Utilisateur : $user", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Date : $createdAt", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(item["input_text"] ?? "", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text("→ ${item["output_text"] ?? ""}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStars(averageStars),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tout l'historique")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(child: Text("Aucune traduction trouvée"))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) => _buildItem(history[index]),
                ),
    );
  }
}
