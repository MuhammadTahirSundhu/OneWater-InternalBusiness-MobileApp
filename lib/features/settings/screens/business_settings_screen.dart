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

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends ConsumerState<BusinessSettingsScreen> {
  Future<void> _editSetting(String key, dynamic currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());
    
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue != null && newValue != currentValue.toString()) {
      try {
        final dio = ref.read(dioClientProvider);
        
        // Attempt to parse as number if possible
        dynamic parsedValue = newValue;
        if (num.tryParse(newValue) != null) {
          parsedValue = num.tryParse(newValue);
        } else if (newValue.toLowerCase() == 'true') {
          parsedValue = true;
        } else if (newValue.toLowerCase() == 'false') {
          parsedValue = false;
        }

        await dio.put(
          '${ApiEndpoints.settings}/$key',
          data: {'value': parsedValue},
        );
        ref.invalidate(settingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Setting updated'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Business Settings')),
      body: settingsAsync.when(
        data: (settings) {
          if (settings.isEmpty) {
            return const Center(child: Text('No settings configured yet'));
          }
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
                  onTap: () => _editSetting(setting['key'], setting['value']),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Error loading settings')),
      ),
    );
  }
}

