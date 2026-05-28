import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../onboarding/providers/auth_provider.dart';

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.notifications);
  return response.data as List<dynamic>;
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              try {
                await ref.read(dioClientProvider).post(ApiEndpoints.markAllRead);
                ref.invalidate(notificationsProvider);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_off_outlined,
                title: 'No notifications',
                subtitle: 'You are all caught up!',
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['is_read'] as bool;
                final date = DateTime.parse(notif['created_at']);

                return Container(
                  color: isRead ? Colors.transparent : AppColors.primarySurface.withOpacity(0.3),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? AppColors.surface : AppColors.primary,
                      child: Icon(
                        _getIcon(notif['type']),
                        color: isRead ? AppColors.textSecondary : Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notif['title'],
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif['body'], style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.timeAgo(date),
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      if (!isRead) {
                        try {
                          await ref.read(dioClientProvider).post(ApiEndpoints.markNotificationRead(notif['id']));
                          ref.invalidate(notificationsProvider);
                        } catch (_) {}
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading notifications')),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'overdue_payment_summary':
        return Icons.warning_amber_rounded;
      case 'new_sale':
        return Icons.receipt_long;
      default:
        return Icons.notifications;
    }
  }
}
