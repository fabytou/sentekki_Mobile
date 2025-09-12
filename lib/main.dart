import 'package:flutter/material.dart';
import 'SenTekkiColors.dart';
import 'home.dart';

void main() {
  runApp(const SenTekkiApp());
}

class SenTekkiApp extends StatelessWidget {
  const SenTekkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SenTekki ",
     debugShowCheckedModeBanner: false, // Enlève le bandeau DEBUG

      theme: ThemeData(
        primaryColor: SenTekkiColors.primary,
        scaffoldBackgroundColor: SenTekkiColors.lightGray,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SenTekkiColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SenTekkiColors.primary, width: 2),
          ),
        ),
      ),
      home: const Home(), // première page affichée
    );
  }
}
