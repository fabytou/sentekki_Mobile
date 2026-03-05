import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';
import 'registration/login.dart';
import 'profile_page.dart';
import 'correctionspage.dart';

// ── Palette ──
const Color _kPrimary     = Color(0xFF00C07A);
const Color _kPrimaryDark = Color(0xFF009960);
const Color _kText        = Color(0xFF1A1A1A);

// ════════════════════════════════════════════════
//  CUSTOM APP BAR
// ════════════════════════════════════════════════
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? currentPageTitle;
  const CustomAppBar({super.key, this.currentPageTitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: preferredSize.height + topPadding,
      color: Colors.white,
      padding: EdgeInsets.only(
        top: topPadding,
        left: 16,
        right: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Logo rond vert avec lettre S ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D688), Color(0xFF009960)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Titre de la page ──
          Text(
            currentPageTitle ?? 'Senteki',
            style: const TextStyle(
              color: _kText,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: 0.1,
            ),
          ),

          const Spacer(),

          // ── Bouton menu carré avec bordure ──
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () {
                if (Scaffold.of(ctx).hasEndDrawer) {
                  Scaffold.of(ctx).openEndDrawer();
                } else {
                  debugPrint("Aucun endDrawer défini sur cette page.");
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.black54,
                  size: 22,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
//  CUSTOM SIDE MENU
// ════════════════════════════════════════════════
class CustomSideMenu extends StatelessWidget {
  const CustomSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth         = Provider.of<AuthState>(context);
    final String role  = auth.userRole ?? "";
    final bool isCorr  = auth.isLoggedIn &&
        (role.toLowerCase().contains('correcteur') ||
         role.toLowerCase().contains('corrector') ||
         role.toLowerCase().contains('admin'));
    final String init  = (auth.userFullName?.isNotEmpty == true)
        ? auth.userFullName![0].toUpperCase()
        : "U";

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: Column(
        children: [

          // ── Header gradient ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 58, left: 24, right: 24, bottom: 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00C07A), Color(0xFF007A4D)],
              ),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar cercle
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(init,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(auth.userFullName ?? "Utilisateur",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                // Badge rôle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    auth.isLoggedIn ? role : "Invité",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _item(context, Icons.person_rounded, "Profil",
                    const Color(0xFF00C07A),
                    dest: auth.isLoggedIn
                        ? const ProfileScreen()
                        : const LoginScreen()),
                _item(context, Icons.translate_rounded, "Traduire",
                    const Color(0xFF4285F4),
                    routeName: '/translation'),
                _item(context, Icons.menu_book_rounded, "Dictionnaire",
                    const Color(0xFFFF6B35),
                    routeName: '/dictionary'),
                if (isCorr) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 4),
                    child: Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("CORRECTEUR",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                  ),
                  _item(context, Icons.fact_check_rounded, "Corrections",
                      const Color(0xFFFFB800),
                      dest: const PendingCorrectionsPage()),
                ],
              ],
            ),
          ),

          // ── Déconnexion ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: GestureDetector(
              onTap: () async {
                if (auth.isLoggedIn) {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                } else {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: auth.isLoggedIn
                      ? const Color(0xFFFFF0F0)
                      : const Color(0xFFF0FBF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: auth.isLoggedIn
                        ? Colors.red.shade100
                        : _kPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      auth.isLoggedIn
                          ? Icons.logout_rounded
                          : Icons.login_rounded,
                      size: 20,
                      color: auth.isLoggedIn
                          ? Colors.red.shade400
                          : _kPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      auth.isLoggedIn ? "Déconnexion" : "Connexion",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: auth.isLoggedIn
                            ? Colors.red.shade400
                            : _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    Widget? dest,
    String? routeName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kText)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade300, size: 20),
        onTap: () {
          Navigator.pop(context);
          if (routeName != null) {
            Navigator.pushReplacementNamed(context, routeName);
          } else if (dest != null) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => dest));
          }
        },
      ),
    );
  }
}