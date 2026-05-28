import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../onboarding/providers/auth_provider.dart';

final settingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.settings);
  return response.data as List<dynamic>;
});

class BusinessSettingsScreen extends ConsumerWidget {
  const BusinessSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Business Settings')),
      body: settingsAsync.when(
        data: (settings) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settings.length,
            itemBuilder: (context, index) {
              final setting = settings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(setting['key'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(setting['value'].toString()),
                  trailing: const Icon(Icons.edit, color: AppColors.primary),
                  onTap: () {},
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading settings')),
      ),
    );
  }
}
