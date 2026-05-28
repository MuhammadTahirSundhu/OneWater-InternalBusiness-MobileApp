import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../onboarding/providers/auth_provider.dart';
import 'transaction_detail_screen.dart';

class CollectPaymentScreen extends ConsumerStatefulWidget {
  final String id;
  const CollectPaymentScreen({super.key, required this.id});

  @override
  ConsumerState<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  bool _isLoading = false;
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment(double maxAmount) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(
        '${ApiEndpoints.transactions}/${widget.id}/collect-payment',
        data: {
          'amount': amount,
          'payment_method': _paymentMethod,
          'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        },
      );

      if (mounted) {
        ref.invalidate(transactionDetailProvider(widget.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment collected successfully'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionDetailProvider(widget.id));

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Collect Payment')),
        body: transactionAsync.when(
          data: (txn) {
            final balanceDue = txn.totalAmount - txn.amountPaid;

            if (balanceDue <= 0) {
              return const Center(child: Text('This invoice is already fully paid.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Text('Balance Due', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(balanceDue),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount to Collect (PKR)',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      suffixIcon: TextButton(
                        onPressed: () {
                          _amountController.text = balanceDue.toStringAsFixed(0);
                        },
                        child: const Text('Full Amount'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PaymentMethodChip(label: 'Cash', value: 'cash', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
                      _PaymentMethodChip(label: 'Bank Transfer', value: 'bank_transfer', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
                      _PaymentMethodChip(label: 'EasyPaisa', value: 'easypaisa', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
                      _PaymentMethodChip(label: 'JazzCash', value: 'jazzcash', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitPayment(balanceDue),
                      child: const Text('Record Payment'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;

  const _PaymentMethodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      selectedColor: AppColors.primarySurface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
