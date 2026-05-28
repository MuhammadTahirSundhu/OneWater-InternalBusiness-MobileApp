import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../onboarding/providers/auth_provider.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.reportSummary);
  return response.data as Map<String, dynamic>;
});

final recentTransactionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.transactions,
    queryParameters: {'limit': '5', 'offset': '0'},
  );
  return response.data as List<dynamic>;
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dio = ref.read(dioClientProvider);
  try {
    final response = await dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'unread_only': 'true', 'limit': '100'},
    );
    return (response.data as List).length;
  } catch (_) {
    return 0;
  }
});
