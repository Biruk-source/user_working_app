// @dart=2.17

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../animations/animated_background.dart';

class DrawerMenu extends StatefulWidget {
  final String userName;
  final String userEmail;

  const DrawerMenu({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double touchX = 0;
  double touchY = 0;
  bool isTouched = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          touchX = details.localPosition.dx;
          touchY = details.localPosition.dy;
          isTouched = true;
        });
      },
      onPanEnd: (details) {
        setState(() {
          isTouched = false;
        });
      },
      child: Drawer(
        child: Stack(
          children: [
            AnimatedBackground(
              touchX: touchX,
              touchY: touchY,
              isTouched: isTouched,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.01),
                    Theme.of(context).primaryColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Container(
                      height: 200,
                      margin: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromARGB(255, 247, 201, 201),
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : '😋',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.userName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.userEmail,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(height: 9),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Made by Biruk',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/'),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart',
                    onTap: () => Navigator.of(context).pushNamed('/cart'),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.list_outlined,
                    title: 'My Orders',
                    onTap: () => Navigator.of(context).pushNamed('/orders'),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.map_outlined,
                    title: 'Map',
                    onTap: () => Navigator.of(context).pushNamed('/map'),
                  ),
                  const Divider(color: Colors.white24),
                  _buildDrawerItem(
                    context: context,
                    icon: themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    title: themeProvider.themeMode == ThemeMode.dark
                        ? 'Light Mode'
                        : 'Dark Mode',
                    onTap: () => themeProvider.toggleTheme(),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                  const Divider(color: Colors.white24),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: () async {
                      final shouldSignOut = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content:
                              const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldSignOut == true && context.mounted) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
      splashColor: Colors.white.withOpacity(0.2),
    );
  }
}
