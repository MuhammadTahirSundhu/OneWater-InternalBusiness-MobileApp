import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/models/report_model.dart';
import '../../onboarding/providers/auth_provider.dart';

class ReportFilterState {
  final String preset;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  
  ReportFilterState({required this.preset, this.dateFrom, this.dateTo});
}

// ─── Date preset state ────────────────────────────────────────────────────────
final reportFilterProvider = StateProvider<ReportFilterState>((ref) => ReportFilterState(preset: 'last_7_days'));

Map<String, dynamic> _buildQueryParams(ReportFilterState filter) {
  return {
    if (filter.preset != 'custom') 'preset': filter.preset,
    if (filter.preset == 'custom' && filter.dateFrom != null) 'date_from': filter.dateFrom!.toIso8601String().split('T')[0],
    if (filter.preset == 'custom' && filter.dateTo != null) 'date_to': filter.dateTo!.toIso8601String().split('T')[0],
  };
}

// ─── Providers ────────────────────────────────────────────────────────────────
final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportSummary,
    queryParameters: _buildQueryParams(filter),
  );
  return ReportSummary.fromJson(response.data);
});

final salesByProductProvider = FutureProvider.autoDispose<List<SalesByProductItem>>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportSalesByProduct,
    queryParameters: _buildQueryParams(filter),
  );
  return (response.data as List).map((e) => SalesByProductItem.fromJson(e)).toList();
});

final paymentStatusProvider = FutureProvider.autoDispose<List<PaymentBreakdown>>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportPaymentStatus,
    queryParameters: _buildQueryParams(filter),
  );
  final list = response.data['breakdown'] as List;
  return list.map((e) => PaymentBreakdown.fromJson(e)).toList();
});

final revenueTrendProvider = FutureProvider.autoDispose<List<DailyRevenue>>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.reportRevenueTrend,
    queryParameters: _buildQueryParams(filter),
  );
  return (response.data as List).map((e) => DailyRevenue.fromJson(e)).toList();
});
