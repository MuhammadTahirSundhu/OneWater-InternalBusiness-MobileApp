import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/payment_status_badge.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/models/transaction_model.dart';
import '../../onboarding/providers/auth_provider.dart';

class TransactionFilterArgs {
  final String? status;
  final String? search;

  const TransactionFilterArgs({this.status, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilterArgs &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode => status.hashCode ^ search.hashCode;
}

final transactionsProvider = FutureProvider.autoDispose
    .family<List<TransactionModel>, TransactionFilterArgs>((ref, filters) async {
  final dio = ref.read(dioClientProvider);
  final queryParams = <String, dynamic>{
    'limit': '50',
    'offset': '0',
  };
  if (filters.status != null) queryParams['payment_status'] = filters.status;
  if (filters.search != null) queryParams['search'] = filters.search;

  final response = await dio.get(ApiEndpoints.transactions, queryParameters: queryParams);
  return (response.data as List).map((e) => TransactionModel.fromJson(e)).toList();
});

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  String? _statusFilter;
  final _searchController = TextEditingController();

  TransactionFilterArgs get _filters => TransactionFilterArgs(
    status: _statusFilter,
    search: _searchController.text.isNotEmpty ? _searchController.text : null,
  );


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider(_filters));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer or invoice...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  _FilterChip(
                    label: 'Paid',
                    selected: _statusFilter == 'paid',
                    onTap: () => setState(() => _statusFilter = 'paid'),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    selected: _statusFilter == 'pending',
                    onTap: () => setState(() => _statusFilter = 'pending'),
                  ),
                  _FilterChip(
                    label: 'Partial',
                    selected: _statusFilter == 'partial',
                    onTap: () => setState(() => _statusFilter = 'partial'),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_long,
                    title: 'No transactions found',
                    subtitle: 'Create your first sale to get started',
                    actionLabel: 'New Sale',
                    onAction: () => context.push('/transactions/new'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final txn = transactions[index];
                    return _TransactionCard(txn: txn);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel txn;

  const _TransactionCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/transactions/${txn.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          txn.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(txn.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PaymentStatusBadge(status: txn.paymentStatus),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.formatDate(txn.transactionDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                  const Spacer(),
                  Text(
                    txn.itemsSummary,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
