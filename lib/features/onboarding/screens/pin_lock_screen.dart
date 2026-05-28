import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../onboarding/providers/auth_provider.dart';

enum PinMode { verify, setup, confirm }

class PinLockScreen extends ConsumerStatefulWidget {
  final PinMode mode;
  final String? setupPin; // Used in confirm mode to verify match

  const PinLockScreen({
    super.key,
    this.mode = PinMode.verify,
    this.setupPin,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isLoading = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += value;
      _errorMessage = '';
    });
    if (_enteredPin.length == 4) {
      _validatePin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = '';
    });
  }

  Future<void> _validatePin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));

    final storage = ref.read(secureStorageProvider);

    if (widget.mode == PinMode.verify) {
      final savedPin = await storage.getAppPin();
      if (_enteredPin == savedPin) {
        await storage.setLastActive();
        if (mounted) context.go('/dashboard');
      } else {
        _shakeAndReset('Incorrect PIN. Try again.');
      }
    } else if (widget.mode == PinMode.setup) {
      // Go to confirm step
      if (mounted) {
        context.push('/pin-confirm', extra: _enteredPin);
      }
      setState(() {
        _enteredPin = '';
        _isLoading = false;
      });
    } else if (widget.mode == PinMode.confirm) {
      if (_enteredPin == widget.setupPin) {
        await storage.setAppPin(_enteredPin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN set successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/dashboard');
        }
      } else {
        _shakeAndReset('PINs do not match. Try again.');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _shakeAndReset(String message) {
    HapticFeedback.vibrate();
    _shakeController.forward().then((_) => _shakeController.reverse());
    setState(() {
      _enteredPin = '';
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    switch (widget.mode) {
      case PinMode.verify:
        title = 'Enter PIN';
        subtitle = 'Enter your 4-digit PIN to continue';
        break;
      case PinMode.setup:
        title = 'Set PIN';
        subtitle = 'Choose a 4-digit PIN for the app';
        break;
      case PinMode.confirm:
        title = 'Confirm PIN';
        subtitle = 'Re-enter your PIN to confirm';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 32),

            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // PIN Dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeAnimation.value *
                        (_shakeController.value < 0.5 ? 1 : -1),
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppColors.primary : AppColors.cardBorder,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Error message
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _errorMessage.isNotEmpty ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', 'del'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((key) {
                        if (key.isEmpty) return const SizedBox(width: 80, height: 80);
                        return _KeypadButton(
                          label: key,
                          onTap: key == 'del'
                              ? _onDelete
                              : () => _onKeyPressed(key),
                          isDelete: key == 'del',
                          isLoading: _isLoading && _enteredPin.length == 4,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Biometric / Skip
            if (widget.mode == PinMode.verify)
              TextButton.icon(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Logout instead'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete;
  final bool isLoading;

  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.isDelete = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Center(
            child: isDelete
                ? const Icon(Icons.backspace_outlined, color: AppColors.textSecondary)
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
