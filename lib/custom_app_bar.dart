import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';
import 'registration/login.dart';
import 'profile_page.dart'; // Vérifie bien que le nom correspond à ton fichier profil

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.currentPageTitle});

  final String currentPageTitle;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    final bool isAuth = auth.isLoggedIn;
    final String name = auth.userFullName ?? "Invité";

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SenTekki",
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF00A86B), 
              letterSpacing: -0.5
            ),
          ),
          Text(
            currentPageTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w600, 
              color: Colors.grey[600], 
              letterSpacing: 1.0
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            // Redirection directe au clic sur l'avatar
            onTap: () {
              if (isAuth) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isAuth ? const Color(0xFF00A86B).withOpacity(0.1) : Colors.grey[100],
                child: isAuth 
                  ? Text(
                      name[0].toUpperCase(), 
                      style: const TextStyle(
                        color: Color(0xFF00A86B), 
                        fontWeight: FontWeight.bold
                      ),
                    )
                  : const Icon(Icons.person_outline, size: 20, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }
}