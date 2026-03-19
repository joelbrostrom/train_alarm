import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/pages/favorites_page.dart';
import 'package:sov_inte_forbi/pages/home_page.dart';
import 'package:sov_inte_forbi/pages/map_page.dart';
import 'package:sov_inte_forbi/pages/profile_page.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/theme.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_NavShellState>()?.switchTab(index);
  }

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _currentIndex = 0;

  void switchTab(int index) => setState(() => _currentIndex = index);

  final _pages = const [HomePage(), MapPage(), FavoritesPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final auth = context.watch<AuthProvider>();

    if (isWide) {
      return Scaffold(appBar: _buildTopBar(auth), body: _pages[_currentIndex]);
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.star_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(AuthProvider auth) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.train_rounded, color: AppColors.cyan, size: 28),
          const SizedBox(width: 10),
          const Text('Sov Inte Förbi'),
        ],
      ),
      actions: [
        _navButton('Home', Icons.home_rounded, 0),
        _navButton('Map', Icons.map_rounded, 1),
        _navButton('Favorites', Icons.star_rounded, 2),
        _navButton('Profile', Icons.person_rounded, 3),
        const SizedBox(width: 8),
        if (auth.isSignedIn && auth.user?.photoUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(auth.user!.photoUrl!),
            ),
          )
        else if (auth.isSignedIn)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.cyan,
              child: Text(
                auth.user?.displayName.isNotEmpty == true
                    ? auth.user!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => auth.signInWithGoogle(),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign in'),
            ),
          ),
      ],
    );
  }

  Widget _navButton(String label, IconData icon, int index) {
    final selected = _currentIndex == index;
    return TextButton.icon(
      onPressed: () => setState(() => _currentIndex = index),
      icon: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.cyan : AppColors.mistDim,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.cyan : AppColors.mistDim,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
