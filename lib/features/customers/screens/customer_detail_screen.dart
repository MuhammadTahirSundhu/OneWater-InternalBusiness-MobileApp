import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/customer_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/payment_status_badge.dart';
import '../../onboarding/providers/auth_provider.dart';

final customerDetailProvider = FutureProvider.autoDispose.family<CustomerModel, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get('${ApiEndpoints.customers}/$id');
  return CustomerModel.fromJson(response.data);
});

final customerTransactionsProvider = FutureProvider.autoDispose.family<List<TransactionModel>, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get('${ApiEndpoints.transactions}?customer_id=$id&limit=20');
  return (response.data as List).map((e) => TransactionModel.fromJson(e)).toList();
});

class CustomerDetailScreen extends ConsumerWidget {
  final String id;
  const CustomerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(id));
    final transactionsAsync = ref.watch(customerTransactionsProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(customerDetailProvider(id));
            ref.invalidate(customerTransactionsProvider(id));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(customer.phone ?? 'No phone number', style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),

                      // Balances
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              title: 'Total Pending',
                              value: CurrencyFormatter.format(customer.totalPending),
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              title: 'Lifetime Value',
                              value: CurrencyFormatter.format(customer.lifetimeValue),
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              transactionsAsync.when(
                data: (txns) {
                  if (txns.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No transactions yet')),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final txn = txns[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text('Invoice #${txn.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(AppDateUtils.formatDate(txn.transactionDate)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(CurrencyFormatter.format(txn.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                PaymentStatusBadge(status: txn.paymentStatus),
                              ],
                            ),
                            onTap: () => context.push('/transactions/${txn.id}'),
                          ),
                        );
                      },
                      childCount: txns.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, __) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
