import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dictionary_model.dart';
import 'custom_app_bar.dart';
import 'nav_bar.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  List<DictionaryWord> results = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  int currentPage = 1;
  bool hasNextPage = true;
  final int pageSize = 20;
  final int _currentIndex = 1;
  String selectedLetter = "All";
  bool isWolofAlphabet = true;

  static const Color senTekkiGreen = Color(0xFF00A86B);
  static const Color darkBlue = Color(0xFF1A237E);
  static const Color backgroundGrey = Color(0xFFF8FAFB);

  final List<String> wolofAlphabet = [
    "A", "B", "C", "D", "E", "Ë", "F", "G", "I", "J", "K", "L",
    "M", "N", "Ñ", "Ŋ", "O", "P", "Q", "R", "S", "T", "U", "W", "X", "Y"
  ];

  @override
  void initState() {
    super.initState();
    fetchWords();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (hasNextPage && !isFetchingMore && !isLoading) {
        fetchWords(isLoadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchWords({String query = "", bool isLoadMore = false}) async {
    if (!mounted) return;

    if (isLoadMore) {
      setState(() => isFetchingMore = true);
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
        results.clear();
      });
    }

    try {
      String searchTerm = query.isEmpty ? searchController.text : query;
      if (selectedLetter != "All" && searchTerm.isEmpty) {
        searchTerm = selectedLetter.toLowerCase();
      }

      final String baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
      final url = Uri.parse('$baseUrl/api/search/?search=$searchTerm&page=$currentPage&page_size=$pageSize');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawData = data['results'] ?? [];

        if (mounted) {
          setState(() {
            final newWords = rawData.map((w) => DictionaryWord.fromJson(w)).toList();
            if (isLoadMore) {
              results.addAll(newWords);
            } else {
              results = newWords;
            }
            currentPage++;
            hasNextPage = currentPage <= (data['total_pages'] ?? 1);
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur Dictionary API: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchWords(query: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      // --- AJOUTS ICI ---
      appBar: const CustomAppBar(currentPageTitle: "Dictionnaire"),
      endDrawer: const CustomSideMenu(), // Permet d'ouvrir le menu latéral
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1), // Utilise la logique interne
      // ------------------
      body: RefreshIndicator(
        onRefresh: () => fetchWords(),
        color: senTekkiGreen,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderSection(),
              _buildToggleAlphabet(senTekkiGreen),
              _buildLetterGrid(senTekkiGreen),
              const SizedBox(height: 20),
              _buildResultsInfo(),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator(color: senTekkiGreen),
                )
              else
                _buildWordsList(),
              if (isFetchingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: senTekkiGreen, strokeWidth: 2)),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Tes méthodes _build restent identiques ci-dessous...
  Widget _buildHeaderSection() { /* ... */ return Padding(padding: const EdgeInsets.fromLTRB(20, 30, 20, 10), child: Column(children: [const Text("Rechercher un terme", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkBlue)), const SizedBox(height: 20), TextField(controller: searchController, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: "Ex: aada, coutume...", prefixIcon: const Icon(Icons.search, color: Colors.grey), suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); fetchWords(); }) : null, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),),),],),); }
  Widget _buildToggleAlphabet(Color activeColor) { /* ... */ return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFE8EAF6).withOpacity(0.5), borderRadius: BorderRadius.circular(15),), child: Row(children: [_buildToggleItem("Alphabet Wolof", isWolofAlphabet, activeColor), _buildToggleItem("Alphabet Français", !isWolofAlphabet, activeColor),],),); }
  Widget _buildToggleItem(String label, bool isActive, Color color) { return Expanded(child: GestureDetector(onTap: () => setState(() => isWolofAlphabet = (label == "Alphabet Wolof")), child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isActive ? color : Colors.transparent, borderRadius: BorderRadius.circular(12),), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isActive ? Colors.white : Colors.blueGrey, fontWeight: FontWeight.bold)),),),); }
  Widget _buildLetterGrid(Color activeColor) { return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: wolofAlphabet.map((letter) { bool isSelected = selectedLetter == letter; return InkWell(onTap: () { setState(() { selectedLetter = isSelected ? "All" : letter; searchController.clear(); }); fetchWords(); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 42, height: 42, decoration: BoxDecoration(color: isSelected ? activeColor : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],), child: Center(child: Text(letter, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),),),); }).toList(),),); }
  Widget _buildResultsInfo() { return Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), child: Row(children: [const Icon(Icons.sort_by_alpha, size: 18, color: Colors.blueGrey), const SizedBox(width: 8), Text("${results.length} terme(s) trouvé(s)", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),],),); }
  Widget _buildWordsList() { if (results.isEmpty && !isLoading) { return const Padding(padding: EdgeInsets.only(top: 50), child: Center(child: Text("Aucun mot trouvé.", style: TextStyle(color: Colors.grey, fontSize: 16)),),); } return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: results.length, itemBuilder: (context, index) { return _buildWordCard(results[index]); },); }
  Widget _buildWordCard(DictionaryWord word) { return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(word.term, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),), Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF1F3F9), borderRadius: BorderRadius.circular(12)), child: Text(word.code, style: const TextStyle(fontSize: 13, color: senTekkiGreen, fontWeight: FontWeight.bold)),),],), if (word.phonetic.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text("[ ${word.phonetic} ]", style: const TextStyle(color: senTekkiGreen, fontSize: 16)),), const SizedBox(height: 10), Text("Origine: ${word.origin ?? 'inconnue'}", style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF95A5A6), fontSize: 15)), const SizedBox(height: 25), const Text("TEKKI (TRADUCTION)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFAAB8C2), letterSpacing: 1.2)), const SizedBox(height: 8), Text(word.definition, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))), const SizedBox(height: 25), if (word.exampleWo != null && word.exampleWo!.isNotEmpty) Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("“ MISAAL (EXEMPLE)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFAAB8C2))), const SizedBox(height: 15), _buildExampleRow("WO", word.exampleWo!, senTekkiGreen), const SizedBox(height: 12), _buildExampleRow("FR", word.exampleFr ?? "", Colors.blueAccent),],),), const SizedBox(height: 20), const Divider(color: Color(0xFFF1F3F9), thickness: 1.5), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("ID: #${word.id ?? '?'}", style: const TextStyle(color: Color(0xFF95A5A6), fontWeight: FontWeight.w500)), TextButton(onPressed: () {}, child: const Text("Détails →", style: TextStyle(color: senTekkiGreen, fontWeight: FontWeight.bold, fontSize: 16))),],)],),); }
  Widget _buildExampleRow(String lang, String text, Color color) { return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(lang, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Color(0xFF576574)))),],); }
}