import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: DevGateApp()));
}

class DevGateApp extends StatelessWidget {
  const DevGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeteDiv',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final name = await _storage.read(key: 'user_name');
    final pat = await _storage.read(key: 'github_access_token');
    
    setState(() {
      _hasProfile = name != null && name.isNotEmpty && pat != null && pat.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return _hasProfile ? const DashboardScreen() : const OnboardingScreen();
  }
}
