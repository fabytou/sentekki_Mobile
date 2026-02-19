import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key, 
    required this.currentIndex, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF00A86B);
    final auth = Provider.of<AuthState>(context);
    final String role = (auth.userRole ?? "").toLowerCase().trim();
    
    final bool canSeeCorrection = role == "corrector" || 
                                 role == "correcteur" || 
                                 role == "admin" || 
                                 role == "super_admin";

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 15), // Marge réduite pour gagner de l'espace
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Mieux que spaceBetween pour éviter les bords
          children: [
            // Chaque item est enveloppé dans un Flexible pour éviter l'overflow
            Flexible(child: _buildNavItem(Icons.translate_rounded, "Trad", 0, primaryGreen)),
            Flexible(child: _buildNavItem(Icons.menu_book_rounded, "Dico", 1, primaryGreen)),
            Flexible(child: _buildNavItem(Icons.history_rounded, "Hist", 2, primaryGreen)),
            if (canSeeCorrection) 
              Flexible(child: _buildNavItem(Icons.checklist_rtl_rounded, "Corr", 3, primaryGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color activeColor) {
    bool isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? activeColor : Colors.grey[400],
              size: 22, // Taille légèrement réduite
            ),
            if (isSelected)
              Flexible( // <--- EMPECHE LE DEBORDEMENT DU TEXTE
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    label, 
                    overflow: TextOverflow.ellipsis, // Coupe le texte si trop long
                    maxLines: 1,
                    style: TextStyle(
                      color: activeColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Taille légèrement réduite
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}