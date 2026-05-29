import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/models/report_model.dart';
import '../../onboarding/providers/auth_provider.dart';

final reportSummaryProvider = FutureProvider.autoDispose<ReportSummary>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.reportSummary);
  return ReportSummary.fromJson(response.data);
});

final salesByProductProvider = FutureProvider.autoDispose<List<SalesByProductItem>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.reportSalesByProduct);
  return (response.data as List).map((e) => SalesByProductItem.fromJson(e)).toList();
});

final paymentStatusProvider = FutureProvider.autoDispose<List<PaymentBreakdown>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.reportPaymentStatus);
  return (response.data as List).map((e) => PaymentBreakdown.fromJson(e)).toList();
});

final revenueTrendProvider = FutureProvider.autoDispose<List<DailyRevenue>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.reportRevenueTrend, queryParameters: {'days': '7'});
  return (response.data as List).map((e) => DailyRevenue.fromJson(e)).toList();
});
