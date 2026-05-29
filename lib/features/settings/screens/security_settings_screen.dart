import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../onboarding/providers/auth_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final storage = ref.read(secureStorageProvider);
    final pin = await storage.getAppPin();
    if (mounted) {
      setState(() {
        _hasPin = pin != null && pin.isNotEmpty;
      });
    }
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Setup PIN
      context.push('/pin-setup').then((_) => _checkPin());
    } else {
      // Remove PIN
      final storage = ref.read(secureStorageProvider);
      await storage.setAppPin('');
      setState(() => _hasPin = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App PIN removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Security & PIN')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Protect your app with a 4-digit PIN. This will be required when reopening the app after a period of inactivity.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('App PIN Lock', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_hasPin ? 'Enabled' : 'Disabled'),
              value: _hasPin,
              activeTrackColor: AppColors.primary, activeThumbColor: Colors.white,
              onChanged: _togglePin,
            ),
          ),
        ],
      ),
    );
  }
}

