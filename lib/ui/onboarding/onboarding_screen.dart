import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _patCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _saveAndContinue() async {
    if (_nameCtrl.text.isEmpty || _usernameCtrl.text.isEmpty || _patCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _storage.write(key: 'user_name', value: _nameCtrl.text);
    await _storage.write(key: 'github_username', value: _usernameCtrl.text);
    await _storage.write(key: 'github_access_token', value: _patCtrl.text);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFF131314),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3C4043)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8AB4F8).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, size: 48, color: Color(0xFF8AB4F8)),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Welcome to DevGate',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Set up your local profile to continue',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Security Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('100% Decentralized & Secure', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              'DevGate does NOT use PocketBase or any centralized servers. We do not store your keys remotely. Everything is encrypted and runs entirely on your local device for maximum security.',
                              style: TextStyle(color: Colors.green.shade200, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField('Full Name', Icons.person_outline, _nameCtrl),
                const SizedBox(height: 16),
                _buildTextField('GitHub Username', Icons.alternate_email, _usernameCtrl),
                const SizedBox(height: 16),
                _buildTextField('GitHub Personal Access Token (PAT)', Icons.key_outlined, _patCtrl, isObscure: true),
                const SizedBox(height: 8),
                _buildPatInstructions(),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Start Using DevGate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildPatInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8AB4F8).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFF8AB4F8).withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF8AB4F8), size: 16),
              SizedBox(width: 8),
              Text('How to get a Token?', style: TextStyle(color: Color(0xFF8AB4F8), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          SizedBox(height: 8),
          Text('1. Go to GitHub.com → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          Text('2. Click "Generate new token (classic)"', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          Text('3. Check ONLY the "read:user" and "read:org" scopes. (You do NOT need to grant write access unless you plan to push code).', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          Text('4. Do NOT check admin, delete, or other highly sensitive permissions.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}
