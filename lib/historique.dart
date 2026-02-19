import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'auth_state.dart';
import 'nav_bar.dart'; 
import 'home.dart';
import 'correctionspage.dart'; // Import de ta nouvelle page
import 'custom_app_bar.dart';

class TranslationHistoryPage extends StatefulWidget {
  const TranslationHistoryPage({Key? key}) : super(key: key);

  @override
  State<TranslationHistoryPage> createState() => _TranslationHistoryPageState();
}

class _TranslationHistoryPageState extends State<TranslationHistoryPage> {
  List translations = [];
  bool isLoading = true;
  bool isFullHistory = false;
  int _selectedIndex = 2; // Index pour l'historique

  @override
  void initState() {
    super.initState();
    // Utilisation de la méthode sécurisée de AuthState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(isRecent: true);
    });
  }

  // --- LOGIQUE DE NAVIGATION CORRIGÉE ---
  void _onNavigationChanged(int index) {
    if (index == _selectedIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const Home();
        break;
      case 3:
        nextPage = const PendingCorrectionsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  // --- RÉCUPÉRATION DES DONNÉES VIA AUTHSTATE ---
  Future<void> _fetchData({required bool isRecent}) async {
    setState(() => isLoading = true);
    final auth = Provider.of<AuthState>(context, listen: false);
    
    try {
      // On utilise getHistory() qui gère les tokens et le refresh auto
      final response = await auth.getHistory(all: !isRecent);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          translations = data['results'] ?? [];
          isFullHistory = !isRecent;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur Historique: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF00A86B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Fond assorti au reste
      appBar: const CustomAppBar(currentPageTitle: "Historique"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              onRefresh: () => _fetchData(isRecent: !isFullHistory),
              color: primaryGreen,
              child: translations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      itemCount: translations.length + (isFullHistory ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index == translations.length) {
                          return _buildSeeMoreButton(primaryGreen);
                        }
                        return _buildHistoryCard(translations[index], primaryGreen);
                      },
                    ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationChanged,
      ),
    );
  }

  Widget _buildHistoryCard(Map t, Color primaryGreen) {
    String displayUser = "Anonyme";
    if (t['user'] != null && t['user'] is Map) {
      displayUser = t['user']['username'] ?? "Anonyme";
    }

    final dynamic rawNote = t['notes'];
    int rating = 0;
    if (rawNote != null) {
      rating = double.tryParse(rawNote.toString())?.round() ?? 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Coins plus doux
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryGreen.withOpacity(0.1),
                      child: Icon(Icons.person, size: 16, color: primaryGreen),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        displayUser,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIndex) => Icon(
                  starIndex < rating ? Icons.star : Icons.star_border,
                  color: primaryGreen,
                  size: 16,
                )),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Text(
            t['input_text'] ?? '', 
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(
            t['output_text'] ?? '', 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton(Color primaryGreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 30),
        child: ElevatedButton.icon(
          onPressed: () => _fetchData(isRecent: false),
          icon: const Icon(Icons.history, size: 18),
          label: const Text("Voir tout l'historique"),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("Aucune traduction trouvée", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}