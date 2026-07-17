import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/secure_storage_service.dart';
import '../../engines/scanner/scanner_engine.dart';
import '../onboarding/onboarding_screen.dart';

/// Settings screen — profile management, scanner configuration, and about info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Profile controllers
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _patCtrl      = TextEditingController();

  bool _obscurePat   = true;
  bool _isSaving     = false;
  bool _isLoaded     = false;
  double _entropyThreshold = 4.8;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name     = await storageService.getName();
    final username = await storageService.getUsername();
    final token    = await storageService.getToken();
    final threshold = await storageService.getEntropyThreshold();

    setState(() {
      _nameCtrl.text     = name     ?? '';
      _usernameCtrl.text = username ?? '';
      _patCtrl.text      = token    ?? '';
      _entropyThreshold  = threshold;
      _isLoaded          = true;
    });

    // Sync threshold with scanner state
    ref.read(scannerStateProvider.notifier).setEntropyThreshold(threshold);
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty || _usernameCtrl.text.isEmpty || _patCtrl.text.isEmpty) {
      _snack('All profile fields are required.');
      return;
    }
    setState(() => _isSaving = true);

    await storageService.saveName(_nameCtrl.text.trim());
    await storageService.saveUsername(_usernameCtrl.text.trim());
    await storageService.saveToken(_patCtrl.text.trim());
    await storageService.saveEntropyThreshold(_entropyThreshold);

    // Update scanner in-memory state immediately
    ref.read(scannerStateProvider.notifier).setEntropyThreshold(_entropyThreshold);

    setState(() => _isSaving = false);
    _snack('Settings saved successfully.');
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Reset DevGate', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will delete your profile, GitHub token, and all settings. '
          'The app will return to the onboarding screen. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await storageService.clearAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _patCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8AB4F8)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ──────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF8AB4F8), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your profile, scanner configuration, and app preferences.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // ── Profile section ──────────────────────────────────────────
              _SectionHeader(title: 'Profile', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  children: [
                    _buildField(
                      label: 'Full Name',
                      icon: Icons.badge_outlined,
                      controller: _nameCtrl,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'GitHub Username',
                      icon: Icons.alternate_email,
                      controller: _usernameCtrl,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'GitHub Personal Access Token',
                      icon: Icons.key_outlined,
                      controller: _patCtrl,
                      obscure: _obscurePat,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePat ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePat = !_obscurePat),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8AB4F8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Scanner configuration ────────────────────────────────────
              _SectionHeader(title: 'Scanner Configuration', icon: Icons.tune),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entropy Detection Threshold',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Higher = fewer false positives. Lower = catches more.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8AB4F8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF8AB4F8).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _entropyThreshold.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Color(0xFF8AB4F8),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF8AB4F8),
                        thumbColor: const Color(0xFF8AB4F8),
                        inactiveTrackColor: const Color(0xFF3C4043),
                        overlayColor:
                            const Color(0xFF8AB4F8).withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: _entropyThreshold,
                        min: 3.0,
                        max: 7.0,
                        divisions: 40,
                        onChanged: (val) =>
                            setState(() => _entropyThreshold = val),
                        onChangeEnd: (val) async {
                          ref
                              .read(scannerStateProvider.notifier)
                              .setEntropyThreshold(val);
                          await storageService.saveEntropyThreshold(val);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('3.0 (sensitive)',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                        const Text('7.0 (strict)',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF3C4043)),
                    const SizedBox(height: 12),
                    // Preset buttons
                    const Text(
                      'Presets',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _PresetChip(
                          label: 'Sensitive (4.0)',
                          description: 'More findings, more noise',
                          active: _entropyThreshold == 4.0,
                          color: Colors.orangeAccent,
                          onTap: () => setState(() => _entropyThreshold = 4.0),
                        ),
                        _PresetChip(
                          label: 'Default (4.8)',
                          description: 'Recommended balance',
                          active: _entropyThreshold == 4.8,
                          color: const Color(0xFF8AB4F8),
                          onTap: () => setState(() => _entropyThreshold = 4.8),
                        ),
                        _PresetChip(
                          label: 'Strict (5.5)',
                          description: 'Only high-confidence secrets',
                          active: _entropyThreshold == 5.5,
                          color: Colors.greenAccent,
                          onTap: () => setState(() => _entropyThreshold = 5.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── About ────────────────────────────────────────────────────
              _SectionHeader(title: 'About', icon: Icons.info_outline),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  children: [
                    _AboutRow(label: 'Application', value: 'DevGate'),
                    _AboutRow(label: 'Version', value: '1.0.0'),
                    _AboutRow(label: 'Flutter SDK', value: '^3.12.2'),
                    _AboutRow(label: 'State Management', value: 'Riverpod 3.x'),
                    _AboutRow(
                      label: 'Storage',
                      value: 'flutter_secure_storage (on-device only)',
                    ),
                    _AboutRow(label: 'Regex Patterns', value: '22 secret patterns'),
                    _AboutRow(
                      label: 'Privacy',
                      value: 'No telemetry. No remote servers.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Danger zone ──────────────────────────────────────────────
              _SectionHeader(
                title: 'Danger Zone',
                icon: Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reset DevGate',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Deletes your profile, GitHub token, and all saved settings. '
                            'You will be taken back to the onboarding screen.',
                            style: TextStyle(
                                color: Colors.red.shade200,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _resetApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reset App'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: child,
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.deepNavy,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8AB4F8))),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.color = const Color(0xFF8AB4F8),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
              color: color, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final String description;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.description,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.7) : const Color(0xFF3C4043),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white54,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
