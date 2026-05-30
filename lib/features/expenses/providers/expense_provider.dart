import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/models/expense_model.dart';
import '../../onboarding/providers/auth_provider.dart';

final expensesProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.expenses);
  return (response.data as List).map((e) => ExpenseModel.fromJson(e)).toList();
});

final amountInListProvider = FutureProvider.autoDispose<List<AmountInModel>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.amountIn);
  return (response.data as List).map((e) => AmountInModel.fromJson(e)).toList();
});
