import 'dart:ui';

import 'package:flutter/src/material/colors.dart';

class SenTekkiColors {
  static const Color primary = Color(0xFF06461D);   // vert foncé identique à Home
  static const Color secondary = Color(0xFF74788d); // gris secondaire
  static const Color success = Color(0xFF2ab57d);   // vert succès
  static const Color info = Color(0xFF4ba6ef);      // bleu info
  static const Color warning = Color(0xFFffbf53);   // jaune alerte
  static const Color danger = Color(0xFFfd625e);    // rouge erreur
  static const Color dark = Color(0xFF212529);      // texte sombre
  static const Color lightGray = Color(0xFFe9e9ef); // fond clair
  static const Color logo = Color(0xFF2e2f45);      // couleur du logo
  static const Color lintW = Color(0xFFe4eada);
  static const Color greenW = Color(0xFFbcd490);
  static const Color greenO = Color(0xFF90b714);

  // ✅ Couleur de fond par défaut
  static const Color background = Color(0xFFF8F9FA);

  static MaterialColor? get primaryMaterial => null; 
}
