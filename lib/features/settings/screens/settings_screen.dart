import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../onboarding/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    final isAdminOrManager = user?.isAdminOrManager ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    user?.initials ?? '?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.roleDisplayName ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isAdminOrManager)
            _MenuTile(
              icon: Icons.bar_chart,
              label: 'Reports',
              subtitle: 'Sales analytics & charts',
              onTap: () => context.push('/reports'),
            ),

          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            subtitle: 'Payment reminders & alerts',
            onTap: () => context.push('/notifications'),
          ),

          if (isAdmin)
            _MenuTile(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              subtitle: 'Manage products & prices',
              onTap: () => context.push('/products'),
            ),

          if (isAdmin)
            _MenuTile(
              icon: Icons.people_outline,
              label: 'Manage Users',
              subtitle: 'Add or edit staff accounts',
              onTap: () => context.push('/settings/users'),
            ),

          if (isAdmin)
            _MenuTile(
              icon: Icons.history,
              label: 'Audit Logs',
              subtitle: 'Activity history',
              onTap: () => context.push('/audit-logs'),
            ),

          if (isAdmin)
            _MenuTile(
              icon: Icons.business,
              label: 'Business Settings',
              subtitle: 'Invoice, credit policy, etc.',
              onTap: () => context.push('/settings/business'),
            ),

          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            subtitle: 'Profile, password, notifications',
            onTap: () => context.push('/settings'),
          ),

          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.logout,
            label: 'Logout',
            subtitle: 'Sign out of your account',
            iconColor: AppColors.danger,
            onTap: () async {
              final confirmed = await ConfirmationDialog.show(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                confirmLabel: 'Logout',
                confirmColor: AppColors.danger,
                icon: Icons.logout,
              );
              if (confirmed == true) {
                await ref.read(authStateProvider.notifier).logout();
              }
            },
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'OneWater Pakistan v1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}
