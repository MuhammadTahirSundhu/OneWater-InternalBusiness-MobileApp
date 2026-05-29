import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/payment_status_badge.dart';
import '../../onboarding/providers/auth_provider.dart';

final transactionDetailProvider = FutureProvider.autoDispose.family<TransactionModel, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get('${ApiEndpoints.transactions}/$id');
  return TransactionModel.fromJson(response.data);
});

class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {},
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (txn) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(txn),
              const SizedBox(height: 16),
              _buildCustomerInfo(txn),
              const SizedBox(height: 16),
              _buildItems(txn),
              const SizedBox(height: 16),
              _buildTotals(txn),
              if (txn.paymentStatus != 'paid') ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/transactions/$id/collect'),
                    icon: const Icon(Icons.payment),
                    label: const Text('Collect Payment'),
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stackTrace) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(TransactionModel txn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice #${txn.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text(AppDateUtils.formatDateTime(txn.transactionDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          PaymentStatusBadge(status: txn.paymentStatus),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(TransactionModel txn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(txn.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (txn.customerPhone != null) ...[
            const SizedBox(height: 4),
            Text(txn.customerPhone!, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildItems(TransactionModel txn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...txn.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(CurrencyFormatter.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTotals(TransactionModel txn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', txn.subtotal),
          if (txn.discount > 0) _summaryRow('Discount', -txn.discount, color: AppColors.success),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(CurrencyFormatter.format(txn.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('Amount Paid', txn.amountPaid),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.danger)),
              Text(CurrencyFormatter.format(txn.totalAmount - txn.amountPaid), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.danger)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(CurrencyFormatter.format(amount), style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
