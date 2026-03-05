import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  // Le paramètre onTap devient optionnel car on gère la navigation en interne
  final Function(int)? onTap;

  const CustomBottomNavBar({
    super.key, 
    required this.currentIndex, 
    this.onTap
  });

  // --- LOGIQUE DE NAVIGATION CENTRALISÉE ---
  void _handleNavigation(BuildContext context, int index) {
    // Si on clique sur l'icône de la page où on est déjà, on ne fait rien
    if (index == currentIndex) return;

    // Redirection basée sur l'index avec remplacement de route pour la performance
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/translation');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/dictionary');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/corrections');
        break;
    }

    // On appelle quand même onTap si jamais une page a besoin d'un traitement spécial
    if (onTap != null) onTap!(index);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00A86B);
    final auth = Provider.of<AuthState>(context);
    final String role = (auth.userRole ?? "").toLowerCase().trim();
    
    // Vérification des droits d'accès pour l'onglet correction
    final bool canSeeCorrection = role == "corrector" || 
                                  role == "correcteur" || 
                                  role == "admin" || 
                                  role == "super_admin";

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 15),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(child: _buildNavItem(context, Icons.text_fields_rounded, "Trad", 0, primaryGreen)),
            Flexible(child: _buildNavItem(context, Icons.menu_book_rounded, "Dico", 1, primaryGreen)),
            Flexible(child: _buildNavItem(context, Icons.history_rounded, "Hist", 2, primaryGreen)),
            if (canSeeCorrection) 
              Flexible(child: _buildNavItem(context, Icons.checklist_rtl_rounded, "Corr", 3, primaryGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, Color activeColor) {
    bool isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? activeColor : Colors.grey[400],
              size: 22,
            ),
            if (isSelected)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    label, 
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: activeColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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