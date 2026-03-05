import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_constants.dart';

class AuthState extends ChangeNotifier {
  // --- Variables d'état ---
  bool _isLoggedIn = false;
  String? _token;
  String? _refreshToken;

  // --- Données utilisateur ---
  String? _userFullName;
  String? _userProfilePicUrl;
  String? _userRole;
  String? _userEmail;      
  String? _requestStatus; 

  // --- Données pour la correction ---
  String? _pendingText;
  int? _pendingSentenceId;
  int? _pendingTranslationId;

  // --- Dernière traduction ---
  String? _lastTranslatedText;
  List<String> _lastTranslatedSentences = [];
  int? _lastTranslationId;

  final String _baseUrl = ApiConstants.baseUrl;

  // --- GETTERS ---
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthenticated => _isLoggedIn; 
  String? get token => _token;
  String? get userFullName => _userFullName;
  String? get userProfilePicUrl => _userProfilePicUrl;
  String? get userRole => _userRole;
  String? get userEmail => _userEmail;         
  String? get requestStatus => _requestStatus; 

  String? get pendingText => _pendingText;
  int? get pendingSentenceId => _pendingSentenceId;
  int? get pendingTranslationId => _pendingTranslationId;

  String? get lastTranslatedText => _lastTranslatedText;
  List<String> get lastTranslatedSentences => _lastTranslatedSentences;
  int? get lastTranslationId => _lastTranslationId;

  // --- GESTION DU PROFIL ET PERSISTANCE ---
  Future<void> _setUserData({
    required String fullName, 
    String? photoUrl, 
    String? role, 
    String? email, 
    String? status
  }) async {
    _userFullName = fullName;
    _userProfilePicUrl = photoUrl;
    _userRole = role;
    _userEmail = email;
    _requestStatus = status;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userFullName', fullName);
    if (photoUrl != null) await prefs.setString('userProfilePicUrl', photoUrl);
    if (role != null) await prefs.setString('userRole', role);
    if (email != null) await prefs.setString('userEmail', email);
    if (status != null) await prefs.setString('requestStatus', status);

    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userFullName = prefs.getString('userFullName');
    _userProfilePicUrl = prefs.getString('userProfilePicUrl');
    _userRole = prefs.getString('userRole');
    _userEmail = prefs.getString('userEmail');
    _requestStatus = prefs.getString('requestStatus');
    notifyListeners();
  }

  Future<void> _clearUserData() async {
    _userFullName = null;
    _userProfilePicUrl = null;
    _userRole = null;
    _userEmail = null;
    _requestStatus = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userFullName');
    await prefs.remove('userProfilePicUrl');
    await prefs.remove('userRole');
    await prefs.remove('userEmail');
    await prefs.remove('requestStatus');

    notifyListeners();
  }

  // --- AUTHENTIFICATION ---
  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _isLoggedIn = (_token != null && _token!.isNotEmpty);

    if (_isLoggedIn) {
      await _loadUserData();
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final url = Uri.parse("$_baseUrl/api/login/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        _refreshToken = data['refresh'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('refreshToken', _refreshToken!);

        await _setUserData(
          fullName: data['username'] ?? username,
          photoUrl: null,
          role: data['profil'] ?? 'Utilisateur',
          email: data['email'],
          status: data['request_status'],
        );

        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await _clearUserData();
    _isLoggedIn = false;
    _token = null;
    _refreshToken = null;
    clearPendingData();
    notifyListeners();
  }

  // --- DEMANDE POUR DEVENIR CORRECTEUR ---
  Future<bool> requestCorrectorRole() async {
    try {
      final response = await postWithAuth("/api/request/corrector/", {});

      if (response.statusCode == 200) {
        _requestStatus = 'pending';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('requestStatus', 'pending');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Request Error: $e");
      return false;
    }
  }

  // --- RÉCUPÉRATION DE L'HISTORIQUE ---
  Future<http.Response> getHistory({bool all = false}) async {
    final endpoint = all ? "/api/history/all/" : "/api/history/recent/";
    final url = Uri.parse("$_baseUrl$endpoint");

    Map<String, String> headers = {"Content-Type": "application/json"};
    if (_token != null) {
      headers["Authorization"] = "Bearer $_token";
    }

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401 && _token != null) {
      final success = await _attemptTokenRefresh();
      if (success) {
        headers["Authorization"] = "Bearer $_token";
        return await http.get(url, headers: headers);
      }
    }
    return response;
  }

  // --- REQUÊTES AUTHENTIFIÉES (JSON) ---
  Future<http.Response> getWithAuth(String endpoint, {bool retry = true}) async {
    if (_token == null) throw Exception("Non authentifié");
    final url = Uri.parse("$_baseUrl$endpoint");
    var response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
    );

    if (response.statusCode == 401 && retry) {
      final success = await _attemptTokenRefresh();
      if (success) return getWithAuth(endpoint, retry: false);
    }
    return response;
  }

  Future<http.Response> postWithAuth(String endpoint, Map<String, dynamic> body, {bool retry = true}) async {
    if (_token == null) throw Exception("Non authentifié");
    final url = Uri.parse("$_baseUrl$endpoint");
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && retry) {
      final success = await _attemptTokenRefresh();
      if (success) return postWithAuth(endpoint, body, retry: false);
    }
    return response;
  }

  // --- NOUVEAU : ENVOI DE FICHIERS (MULTIPART) ---
  Future<http.StreamedResponse> sendMultipartWithAuth(http.MultipartRequest request, {bool retry = true}) async {
    // Ajout du Token Bearer
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    // Header Accept requis pour le JSON en retour
    request.headers['Accept'] = 'application/json';

    var streamedResponse = await request.send();

    // Gestion du rafraîchissement de session automatique
    if (streamedResponse.statusCode == 401 && retry && _refreshToken != null) {
      final success = await _attemptTokenRefresh();
      if (success) {
        // Note: Sur un MultipartRequest, on ne peut pas faire un retry simple
        // car le flux de données du fichier est déjà fermé après request.send().
        // L'utilisateur devra généralement relancer l'action si le token expire pile à ce moment.
        debugPrint("Token refresh réussi après 401 Multipart");
      }
    }

    return streamedResponse;
  }

  // --- TOKEN REFRESH ---
  Future<bool> _attemptTokenRefresh() async {
    if (_refreshToken == null) return false;
    final url = Uri.parse("$_baseUrl/api/token/refresh/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Refresh Token Error: $e");
    }
    await logout(); 
    return false;
  }

  // --- SETTERS DONNÉES TEMPORAIRES ---
  void setPendingText(String text) => { _pendingText = text, notifyListeners() };
  void setPendingSentenceId(int id) => { _pendingSentenceId = id, notifyListeners() };
  void setPendingTranslationId(int? id) => { _pendingTranslationId = id, notifyListeners() };
  
  void clearPendingData() {
    _pendingText = null;
    _pendingSentenceId = null;
    _pendingTranslationId = null;
    notifyListeners();
  }

  void clearLastTranslationData() {
    _lastTranslatedText = null;
    _lastTranslatedSentences = [];
    _lastTranslationId = null;
    notifyListeners();
  }
}