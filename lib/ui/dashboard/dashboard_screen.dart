import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'widgets/drop_zone.dart';
import '../git/git_panel_screen.dart';
import '../logs/log_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  bool get isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  // Build pages lazily so heavy widgets aren't instantiated until first visit.
  static const List<Widget> _pages = [
    Padding(
      padding: EdgeInsets.all(24.0),
      child: DropZoneWidget(),
    ),
    GitPanelScreen(),
    LogScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (
      icon: Icons.security_outlined,
      selectedIcon: Icons.security,
      label: 'Scanner',
    ),
    (
      icon: Icons.source_outlined,
      selectedIcon: Icons.source,
      label: 'Git / GitHub',
    ),
    (
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      label: 'Activity Log',
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => windowManager.startDragging(),
                child: AppBar(
                  elevation: 0,
                  centerTitle: false,
                  title: Row(
                    children: [
                      const Icon(Icons.developer_board,
                          size: 20, color: Color(0xFF4285F4)),
                      const SizedBox(width: 8),
                      Text(
                        'DevGate Workspace',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Close',
                      onPressed: windowManager.close,
                    ),
                  ],
                ),
              ),
            )
          : AppBar(
              title: const Text(
                'DevGate Workspace',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
      body: isMobile
          ? _pages[_selectedIndex]
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.selected,
                  groupAlignment: -0.9,
                  destinations: [
                    for (final item in _navItems)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(
                    thickness: 1, width: 1, color: Colors.white10),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              destinations: [
                for (final item in _navItems)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            )
          : null,
    );
  }
}
