import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    (icon: Icons.map_outlined, active: Icons.map, label: 'Map'),
    (icon: Icons.favorite_outline, active: Icons.favorite, label: 'Favorites'),
    (icon: Icons.add_circle_outline, active: Icons.add_circle, label: 'Add'),
    (icon: Icons.inbox_outlined, active: Icons.inbox, label: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: [
          for (var i = 0; i < _items.length; i++)
            BottomNavigationBarItem(
              icon: Icon(_items[i].icon),
              activeIcon: Icon(_items[i].active),
              label: _items[i].label,
            ),
        ],
      ),
    );
  }
}
