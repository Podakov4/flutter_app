import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final Widget navigationShell;

  static const List<_ShellDestination> _destinations = <_ShellDestination>[
    _ShellDestination(
      location: '/home',
      label: 'Главная',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _ShellDestination(
      location: '/access',
      label: 'Подключение',
      icon: Icons.power_settings_new_outlined,
      selectedIcon: Icons.power_settings_new_rounded,
    ),
    _ShellDestination(
      location: '/devices',
      label: 'Устройства',
      icon: Icons.devices_other_outlined,
      selectedIcon: Icons.devices_other_rounded,
    ),
    _ShellDestination(
      location: '/profile',
      label: 'Профиль',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
    _ShellDestination(
      location: '/settings',
      label: 'Настройки',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;

    for (int i = 0; i < _destinations.length; i++) {
      final String root = _destinations[i].location;
      if (location == root || location.startsWith('$root/')) {
        return i;
      }
    }

    if (location == '/subscription' || location.startsWith('/subscription/')) {
      return 0;
    }

    if (location == '/logs' || location.startsWith('/logs/')) {
      return 1;
    }

    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final String target = _destinations[index].location;
    final String current = GoRouterState.of(context).matchedLocation;

    if (current == target) {
      return;
    }

    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);
    final bool wide = MediaQuery.of(context).size.width >= 900;

    if (wide) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            SafeArea(
              child: NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: (int index) =>
                    _onDestinationSelected(context, index),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  child: Column(
                    children: const <Widget>[
                      FlutterLogo(size: 28),
                      SizedBox(height: 10),
                      Text(
                        'Freeth',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                destinations: _destinations.map((d) {
                  return NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  );
                }).toList(),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (int index) =>
            _onDestinationSelected(context, index),
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.location,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String location;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
