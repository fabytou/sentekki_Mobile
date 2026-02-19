import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'auth_state.dart';
import 'correction.dart';
import 'custom_app_bar.dart';
import 'nav_bar.dart';
import 'home.dart';

class PendingCorrectionsPage extends StatefulWidget {
  const PendingCorrectionsPage({Key? key}) : super(key: key);

  @override
  State<PendingCorrectionsPage> createState() => _PendingCorrectionsPageState();
}

class _PendingCorrectionsPageState extends State<PendingCorrectionsPage> {
  // Couleurs Officielles de l'application
  final Color primaryGreen = const Color(0xFF00A86B); // Ton vert bouton "Traduire"
  final Color lightBackground = const Color(0xFFF4F7F6); // Gris bleuté très clair
  
  bool _isLoading = true;
  List<dynamic> _allPending = [];
  List<dynamic> _filteredList = [];
  
  String _searchQuery = "";
  String _selectedLetter = "All";
  String _selectedStatus = "Tous les statuts";
  int _selectedIndex = 3;

  final List<String> _alphabet = ["All", ..."ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")];
  final List<String> _statuses = ["Tous les statuts", "PENDING", "CORRECTED"];

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    try {
      final response = await auth.getWithAuth("/api/translations/pending/");
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _allPending = data is List ? data : (data['results'] ?? []);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredList = _allPending.where((item) {
        final source = (item['input_text'] ?? "").toString().toLowerCase();
        final target = (item['output_text'] ?? "").toString().toLowerCase();
        final status = (item['status'] ?? "PENDING").toString().toUpperCase();

        final matchesSearch = source.contains(_searchQuery.toLowerCase()) || 
                             target.contains(_searchQuery.toLowerCase());
        final matchesLetter = _selectedLetter == "All" || 
                             source.toUpperCase().startsWith(_selectedLetter);
        final matchesStatus = _selectedStatus == "Tous les statuts" || 
                             status == _selectedStatus;

        return matchesSearch && matchesLetter && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    if (auth.userRole != 'corrector') {
       return Scaffold(body: Center(child: Text("Accès correcteur requis", style: TextStyle(color: primaryGreen))));
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: const CustomAppBar(currentPageTitle: "Gestion des Corrections"),
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
                  child: _filteredList.isEmpty ? _buildEmptyState() : _buildList(),
                ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex, 
        onTap: (i) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()))
      ),
    );
  }

  Widget _buildTopSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) { _searchQuery = val; _applyFilters(); },
                  decoration: InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: Icon(Icons.search, size: 22, color: primaryGreen),
                    filled: true,
                    fillColor: lightBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    icon: Icon(Icons.filter_list, color: primaryGreen, size: 20),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) { setState(() => _selectedStatus = val!); _applyFilters(); },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlphabetFilter() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _alphabet.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedLetter == _alphabet[index];
          return GestureDetector(
            onTap: () { setState(() => _selectedLetter = _alphabet[index]); _applyFilters(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade300),
              ),
              child: Center(
                child: Text(_alphabet[index], 
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) => _buildCorrectionCard(_filteredList[index]),
    );
  }

  Widget _buildCorrectionCard(dynamic item) {
    String status = (item['status'] ?? "PENDING").toString().toUpperCase();
    bool isCorrected = status == "CORRECTED";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrected ? primaryGreen.withOpacity(0.1) : Colors.orange.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(6)
                ),
                child: Text(status, style: TextStyle(color: isCorrected ? primaryGreen : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.more_horiz, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("SOURCE (FR)", item['input_text'] ?? ""),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, thickness: 0.5)),
          _buildTextField("TRADUCTION (EN)", item['output_text'] ?? "", isItalic: true),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildIconButton(Icons.visibility_outlined, "Voir", Colors.blueGrey),
              const SizedBox(width: 15),
              _buildIconButton(Icons.edit_note, "Corriger", const Color(0xFFFBC02D), onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CorrectionScreen(sentenceText: item['output_text'] ?? "", sentenceId: 0, translationId: item['id']))).then((_) => _fetchPending());
              }),
              const SizedBox(width: 15),
              _buildIconButton(Icons.delete_outline, "Supprimer", Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String text, {bool isItalic = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      const SizedBox(height: 5),
      Text(text, style: TextStyle(fontSize: 15, color: const Color(0xFF2D3436), fontWeight: FontWeight.w500, fontStyle: isItalic ? FontStyle.italic : FontStyle.normal)),
    ]);
  }

  Widget _buildIconButton(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Aucun résultat trouvé", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}