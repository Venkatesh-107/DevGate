import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'widgets/drop_zone.dart';
import '../git/git_panel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Padding(
      padding: EdgeInsets.all(24.0),
      child: DropZoneWidget(),
    ),
    const GitPanelScreen(),
  ];

  bool get isDesktop => Platform.isLinux || Platform.isMacOS || Platform.isWindows;

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
                onPanStart: (details) {
                  windowManager.startDragging();
                },
                child: AppBar(
                  elevation: 0,
                  centerTitle: false,
                  title: Row(
                    children: [
                      const Icon(Icons.developer_board, size: 20, color: Color(0xFF4285F4)),
                      const SizedBox(width: 8),
                      Text('DevGate Workspace', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        windowManager.close();
                      },
                    ),
                  ],
                ),
              ),
            )
          : AppBar(
              title: const Text('DevGate Workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
      body: isMobile
          ? _pages[_selectedIndex]
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.selected,
                  groupAlignment: -0.9,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.security_outlined),
                      selectedIcon: Icon(Icons.security),
                      label: Text('Scanner'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.source_outlined),
                      selectedIcon: Icon(Icons.source),
                      label: Text('Git/GitHub'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.security_outlined),
                  selectedIcon: Icon(Icons.security),
                  label: 'Scanner',
                ),
                NavigationDestination(
                  icon: Icon(Icons.source_outlined),
                  selectedIcon: Icon(Icons.source),
                  label: 'Git/GitHub',
                ),
              ],
            )
          : null,
    );
  }
}

