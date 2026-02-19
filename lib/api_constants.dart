// lib/api_constants.dart

class ApiConstants {

  // L'URL de base se termine SANS barre oblique (meilleure pratique)
  static const String baseUrl = "http://127.0.0.1:8000"; 
  
  // --- ENDPOINTS DE L'API DJANGO ---
  
  // 1. Traduction (POST) - Correspond à path('translate/', ...)
  static const String translateEndpoint = "/api/translate/";
  
  // 2. Notation (POST) - Correspond à path('note/', ...)
  static const String addNoteEndpoint = "/api/note/"; 
  
  // 3. Correction d'une phrase
  // 🚨 CORRECTION : AJOUT DE LA CONSTANTE MANQUANTE UTILISÉE DANS correction.dart
  static const String addCorrectionEndpoint = "/api/correction/"; 

  // Ancienne constante (qui n'est plus utilisée directement si on utilise addCorrectionEndpoint)
  static const String baseSentenceCorrectionEndpoint = "/api/translate/sentence/";

  // --- ENDPOINTS D'AUTHENTIFICATION (basés sur votre urls.py) ---
  static const String registerEndpoint = "/api/register/";
  static const String loginEndpoint = "/api/login/";
  
  // --- HISTORIQUE (basés sur votre urls.py) ---
  static const String historyRecentEndpoint = "/api/history/recent/";
  static const String historyAllEndpoint = "/api/history/all/";
  
}