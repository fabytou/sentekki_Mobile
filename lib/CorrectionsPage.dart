import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'auth_state.dart';
import 'correction.dart'; 
import 'custom_app_bar.dart';
import 'nav_bar.dart';

class PendingCorrectionsPage extends StatefulWidget {
  const PendingCorrectionsPage({Key? key}) : super(key: key);

  @override
  State<PendingCorrectionsPage> createState() => _PendingCorrectionsPageState();
}

class _PendingCorrectionsPageState extends State<PendingCorrectionsPage> {
  final Color primaryGreen = const Color(0xFF00A86B);
  final Color lightBackground = const Color(0xFFF4F7F6);
  
  bool _isLoading = true;
  List<dynamic> _allPending = [];
  List<dynamic> _filteredList = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedLetter = "All";
  String _selectedStatus = "Tous les statuts";
  final int _selectedIndex = 3; // Index pour cette page

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPending());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPending() async {
    if (!mounted) return;
    final auth = Provider.of<AuthState>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    try {
      final response = await auth.getWithAuth("/api/translate/correct/"); 
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _allPending = data is List ? data : (data['results'] ?? []);
          _applyFilters();
          _isLoading = false;
        });
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur Fetch: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _filteredList = _allPending.where((item) {
        final source = (item['input_text'] ?? "").toString().toLowerCase();
        final status = (item['status'] ?? "pending").toString().toLowerCase().trim();

        final matchesSearch = source.contains(query);
        final matchesLetter = _selectedLetter == "All" || 
                             source.toUpperCase().startsWith(_selectedLetter);
        
        bool matchesStatus = true;
        if (_selectedStatus == "En attente") {
          matchesStatus = (status == "pending");
        } else if (_selectedStatus == "Corrigés") {
          matchesStatus = (status == "corrected");
        }

        return matchesSearch && matchesLetter && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      // --- AJOUTS STRUCTURELS ---
      appBar: const CustomAppBar(currentPageTitle: "Gestion des Corrections"),
      endDrawer: const CustomSideMenu(), // Menu latéral activé
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3), // Navigation auto
      // ---------------------------
      body: Column(
        children: [
          _buildTopSearchSection(),
          _buildAlphabetFilter(),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : RefreshIndicator(
                  onRefresh: _fetchPending,
                  color: primaryGreen,
                  child: _filteredList.isEmpty 
                    ? _buildEmptyState() 
                    : _buildList(),
                ),
          ),
        ],
      ),
    );
  }

  // --- TES WIDGETS DE CONSTRUCTION ---

  Widget _buildTopSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _applyFilters(),
              decoration: InputDecoration(
                hintText: "Rechercher une phrase...",
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                filled: true,
                fillColor: lightBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: lightBackground, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
          items: ["Tous les statuts", "En attente", "Corrigés"]
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            setState(() => _selectedStatus = val!);
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildAlphabetFilter() {
     final alphabet = ["All", ..."ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")];
     return Container(
       height: 45,
       margin: const EdgeInsets.symmetric(vertical: 8),
       child: ListView.builder(
         scrollDirection: Axis.horizontal,
         padding: const EdgeInsets.symmetric(horizontal: 12),
         itemCount: alphabet.length,
         itemBuilder: (context, index) {
           bool isSelected = _selectedLetter == alphabet[index];
           return GestureDetector(
             onTap: () { 
               setState(() => _selectedLetter = alphabet[index]); 
               _applyFilters(); 
             },
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               margin: const EdgeInsets.only(right: 8),
               padding: const EdgeInsets.symmetric(horizontal: 16),
               decoration: BoxDecoration(
                 color: isSelected ? primaryGreen : Colors.white,
                 borderRadius: BorderRadius.circular(10),
                 boxShadow: isSelected ? [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 8)] : [],
                 border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade300),
               ),
               child: Center(
                 child: Text(
                   alphabet[index], 
                   style: TextStyle(
                     color: isSelected ? Colors.white : Colors.black,
                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                   )
                 )
               ),
             ),
           );
         },
       ),
     );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) => _buildCorrectionCard(_filteredList[index]),
    );
  }

  Widget _buildCorrectionCard(dynamic item) {
    final String rawStatus = (item['status'] ?? "pending").toString().toLowerCase().trim();
    final bool isCorrected = (rawStatus == "corrected" || rawStatus == "corrigé");

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrected ? primaryGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrected ? Icons.check_circle : Icons.hourglass_empty,
                        size: 14,
                        color: isCorrected ? primaryGreen : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCorrected ? "CORRIGÉ" : "EN ATTENTE",
                        style: TextStyle(
                          color: isCorrected ? primaryGreen : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item['created_at']?.split('T')[0] ?? "", 
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextSection("SOURCE WOLOF", item['input_text'] ?? "", isBold: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildTextSection("TRADUCTION SUGGÉRÉE", item['output_text'] ?? "", isItalic: true),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: isCorrected ? null : () { 
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CorrectionScreen(
                        sentenceText: item['output_text'] ?? "",
                        sentenceId: 0,
                        translationId: item['id'],
                      ),
                    ),
                  ).then((value) {
                    _fetchPending();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrected ? Colors.grey.shade100 : const Color(0xFFFBC02D),
                  foregroundColor: isCorrected ? Colors.grey : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isCorrected ? Icons.verified : Icons.edit_note, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isCorrected ? "DÉJÀ CORRIGÉ" : "CORRIGER", 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection(String label, String content, {bool isBold = false, bool isItalic = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(
          content, 
          style: TextStyle(
            fontSize: 15, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: const Color(0xFF2D3436)
          )
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Aucune traduction à gérer", 
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fetchPending, 
            child: Text("Actualiser", style: TextStyle(color: primaryGreen))
          )
        ],
      ),
    );
  }
}