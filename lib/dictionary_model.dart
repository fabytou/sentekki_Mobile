class DictionaryWord {
  final int? id;
  final String term;
  final String phonetic;
  final String definition;
  final String code;
  final String? origin;
  final String? exampleWo;
  final String? exampleFr;

  DictionaryWord({
    this.id,
    required this.term,
    required this.phonetic,
    required this.definition,
    required this.code,
    this.origin,
    this.exampleWo,
    this.exampleFr,
  });

  factory DictionaryWord.fromJson(Map<String, dynamic> json) {
    // 1. Extraction sécurisée de 'data'
    final dynamic rawData = json['data'];
    final Map<String, dynamic> data = (rawData is Map) ? Map<String, dynamic>.from(rawData) : {};
    
    String def = "Pas de définition";
    String exWo = "";
    String exFr = "";

    // 2. Extraction de 'sayu_tekki' (Définition et exemples)
    final dynamic sayuTekki = data['sayu_tekki'];
    Map<String, dynamic>? firstTekki;

    if (sayuTekki is List && sayuTekki.isNotEmpty) {
      if (sayuTekki[0] is Map) firstTekki = Map<String, dynamic>.from(sayuTekki[0]);
    } else if (sayuTekki is Map) {
      firstTekki = Map<String, dynamic>.from(sayuTekki);
    }

    if (firstTekki != null) {
      // --- EXTRACTION DÉFINITION (nettalin) ---
      final dynamic tekkiNode = firstTekki['tekki'];
      if (tekkiNode is Map) {
        final dynamic nettalin = tekkiNode['nettalin'];
        if (nettalin is Map) {
          def = nettalin['#text']?.toString() ?? def;
        } else if (nettalin != null) {
          def = nettalin.toString(); // Cas où c'est directement une String
        }
      }

      // --- EXTRACTION EXEMPLES (misaal) ---
      final dynamic misaal = firstTekki['misaal'];
      if (misaal is Map) {
        final dynamic nettalinEx = misaal['nettalin'];
        if (nettalinEx is List && nettalinEx.length >= 2) {
          exWo = _extractText(nettalinEx[0]);
          exFr = _extractText(nettalinEx[1]);
        } else if (nettalinEx != null) {
           exWo = _extractText(nettalinEx);
        }
      }
    }

    // 3. Retour de l'objet avec conversion de types forcée
    return DictionaryWord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ""),
      term: json['mbirmi']?.toString() ?? "Inconnu",
      phonetic: json['teggin']?.toString() ?? "",
      definition: def,
      code: _extractText(data['xeet']).isEmpty ? "nom" : _extractText(data['xeet']),
      origin: data['cosaan']?.toString(),
      exampleWo: exWo,
      exampleFr: exFr,
    );
  }

  // Fonction utilitaire pour extraire du texte de n'importe quelle structure
  static String _extractText(dynamic element) {
    if (element == null) return "";
    if (element is Map) {
      return (element['#text'] ?? element['text'] ?? "").toString();
    }
    return element.toString();
  }
}