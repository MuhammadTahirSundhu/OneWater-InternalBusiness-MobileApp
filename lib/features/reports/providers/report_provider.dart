import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/models/report_model.dart';
import '../../onboarding/providers/auth_provider.dart';

// ─── Date preset state ────────────────────────────────────────────────────────
final reportPresetProvider = StateProvider<String>((ref) => 'last_7_days');

// ─── Providers ────────────────────────────────────────────────────────────────
final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.reportSummary);
  return ReportSummary.fromJson(response.data);
});

final salesByProductProvider = FutureProvider.autoDispose<List<SalesByProductItem>>((ref) async {
  final preset = ref.watch(reportPresetProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportSalesByProduct,
    queryParameters: {'preset': preset},
  );
  return (response.data as List).map((e) => SalesByProductItem.fromJson(e)).toList();
});

final paymentStatusProvider = FutureProvider.autoDispose<List<PaymentBreakdown>>((ref) async {
  final preset = ref.watch(reportPresetProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportPaymentStatus,
    queryParameters: {'preset': preset},
  );
  // API returns {"breakdown": [...]} — unwrap correctly
  final list = response.data['breakdown'] as List;
  return list.map((e) => PaymentBreakdown.fromJson(e)).toList();
});

final revenueTrendProvider = FutureProvider.autoDispose<List<DailyRevenue>>((ref) async {
  final preset = ref.watch(reportPresetProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportRevenueTrend,
    queryParameters: {'preset': preset},
  );
  return (response.data as List).map((e) => DailyRevenue.fromJson(e)).toList();
});
