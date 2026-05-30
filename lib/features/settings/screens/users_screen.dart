import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../onboarding/providers/auth_provider.dart';

final usersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.users);
  return (response.data as List).map((e) => UserModel.fromJson(e)).toList();
});

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  Future<void> _toggleUserActive(UserModel user, bool isActive) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.put(
        '${ApiEndpoints.users}/${user.id}',
        data: {'is_active': isActive},
      );
      ref.invalidate(usersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manage Users')),
      body: usersAsync.when(
        data: (users) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Text(user.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${user.roleDisplayName} • ${user.phone}'),
                  trailing: Switch(
                    value: user.isActive,
                    onChanged: (v) => _toggleUserActive(user, v),
                    activeTrackColor: AppColors.primary, activeThumbColor: Colors.white,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Error loading users')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/users/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}

