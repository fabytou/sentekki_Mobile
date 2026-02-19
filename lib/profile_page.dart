import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';
import 'registration/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? me;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final auth = Provider.of<AuthState>(context, listen: false);
      final response = await auth.getWithAuth('/api/me/');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          me = data;
          loading = false;
        });
        
        // Mise à jour du rôle dans le state global au cas où
        if (data['profil'] != null) {
          String newRole = data['profil']['label'] ?? data['profil']['name'] ?? "Traducteur";
          // Si tu as la méthode dans AuthState, décommente la ligne suivante :
          // auth.updateUserRole(newRole); 
        }
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }
  }

  void _showConfirmationDialog(BuildContext context, AuthState auth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Devenir Correcteur ?"),
          content: const Text(
            "Voulez-vous envoyer une demande à l'administrateur pour devenir correcteur ?"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitRequest(auth);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRequest(AuthState auth) async {
    final success = await auth.requestCorrectorRole();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? "Demande envoyée avec succès !" 
            : "Erreur lors de l'envoi de la demande."),
          backgroundColor: success ? const Color(0xFF00A86B) : Colors.redAccent,
        ),
      );
      if (success) loadProfile(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00A86B);
    const Color darkGrey = Color(0xFF1D2939);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    final auth = Provider.of<AuthState>(context);
    
    final String name = me!['username'] ?? "Utilisateur";
    final String email = me!['email'] ?? "Email non renseigné";
    
    // --- LOGIQUE DE RÉCUPÉRATION DU RÔLE RÉEL ---
    // On vérifie le label (souvent plus propre) sinon le name
    final String roleRaw = (me!['profil']['label'] ?? me!['profil']['name'] ?? "Traducteur").toString();
    final String roleLower = roleRaw.toLowerCase();

    // --- LOGIQUE DE STATUT ---
    final String? requestStatus = me!['request_status'];
    bool isPending = requestStatus == "pending";
    
    // L'utilisateur est considéré correcteur si le mot "correcteur" est dans son rôle
    bool isCorrector = roleLower.contains("correcteur");

    // On affiche le bouton seulement s'il n'est pas correcteur ET pas en attente
    bool showRequestButton = !isCorrector && !isPending;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mon Profil", style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryGreen.withOpacity(0.1),
              child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: primaryGreen, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkGrey)),
            
            // Affichage du rôle dynamique
            Text(
              roleRaw.toUpperCase(), 
              style: const TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w800, letterSpacing: 1.2)
            ),
            
            const SizedBox(height: 35),
            
            _buildInfoCard(Icons.email_outlined, "Email", email),
            
            // Affichage de la carte d'attente
            if (isPending)
              _buildInfoCard(
                Icons.hourglass_empty_rounded, 
                "Statut de la demande", 
                "En cours de traitement par l'admin", 
                color: Colors.orange
              ),

            const SizedBox(height: 30),

            if (showRequestButton)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmationDialog(context, auth),
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text("Demander à devenir Correcteur"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text("Se déconnecter"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, {Color color = const Color(0xFF00A86B)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1D2939), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}