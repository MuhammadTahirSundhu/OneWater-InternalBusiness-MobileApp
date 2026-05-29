import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/customer_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../onboarding/providers/auth_provider.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  ConsumerState<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 - Customer
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customers = [];
  final _customerSearchController = TextEditingController();

  // Step 2 - Products
  List<ProductModel> _products = [];
  final Map<String, int> _quantities = {};

  // Step 3 - Payment
  String _paymentMethod = 'cash';
  String _paymentStatus = 'paid';
  double _discount = 0;
  double _amountPaid = 0;
  final DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _amountPaidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);

      final customersResp = await dio.get(ApiEndpoints.customers);
      _customers = (customersResp.data as List)
          .map((e) => CustomerModel.fromJson(e))
          .toList();

      final productsResp = await dio.get(ApiEndpoints.products);
      _products = (productsResp.data as List)
          .map((e) => ProductModel.fromJson(e))
          .where((p) => p.isActive)
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _subtotal {
    double total = 0;
    for (final entry in _quantities.entries) {
      final product = _products.firstWhere((p) => p.id == entry.key);
      double lineTotal = product.unitPrice * entry.value;
      if (product.hasSecurityDeposit) {
        lineTotal += product.securityDeposit * entry.value;
      }
      total += lineTotal;
    }
    return total;
  }

  double get _totalAmount => _subtotal - _discount;

  List<TransactionItemModel> get _items {
    return _quantities.entries.map((entry) {
      final product = _products.firstWhere((p) => p.id == entry.key);
      double lineTotal = product.unitPrice * entry.value;
      if (product.hasSecurityDeposit) {
        lineTotal += product.securityDeposit * entry.value;
      }
      return TransactionItemModel(
        productId: product.id,
        productName: product.name,
        quantity: entry.value,
        unitPrice: product.unitPrice,
        lineTotal: lineTotal,
      );
    }).toList();
  }

  Future<void> _submitTransaction() async {
    if (_selectedCustomer == null || _quantities.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);

      final paid = _paymentStatus == 'paid'
          ? _totalAmount
          : _paymentStatus == 'partial'
              ? _amountPaid
              : 0.0;

      final body = {
        'customer_id': _selectedCustomer!.id,
        'customer_name': _selectedCustomer!.name,
        'customer_phone': _selectedCustomer!.phone,
        'transaction_date': _transactionDate.toIso8601String().split('T')[0],
        'due_date': _dueDate?.toIso8601String().split('T')[0],
        'items': _items.map((e) => e.toJson()).toList(),
        'subtotal': _subtotal,
        'discount': _discount,
        'total_amount': _totalAmount,
        'amount_paid': paid,
        'payment_status': _paymentStatus,
        'payment_method': _paymentMethod,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      final response = await dio.post(ApiEndpoints.transactions, data: body);

      if (mounted) {
        _showSuccessDialog(response.data);
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

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text(
              'Sale Recorded!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Invoice ${data['invoice_number']}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              CurrencyFormatter.format(data['total_amount']),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Share Invoice'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: _currentStep == 2 ? 'Recording sale...' : 'Loading...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(['Select Customer', 'Select Products', 'Payment & Confirm'][_currentStep]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentStep,
          children: [
            _buildStep1CustomerSelection(),
            _buildStep2ProductSelection(),
            _buildStep3Payment(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed ? _onNext : null,
                child: Text(
                  _currentStep == 2 ? 'Record Sale & Generate Invoice' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0: return _selectedCustomer != null;
      case 1: return _quantities.isNotEmpty;
      case 2: return true;
      default: return false;
    }
  }

  void _onNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      if (_currentStep == 2) {
        _amountPaidController.text = _totalAmount.toStringAsFixed(0);
        _amountPaid = _totalAmount;
      }
    } else {
      _submitTransaction();
    }
  }

  // === STEP 1: Customer Selection ===
  Widget _buildStep1CustomerSelection() {
    final filteredCustomers = _customerSearchController.text.isEmpty
        ? _customers
        : _customers.where((c) =>
            c.name.toLowerCase().contains(_customerSearchController.text.toLowerCase()) ||
            (c.phone?.contains(_customerSearchController.text) ?? false)
          ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _customerSearchController,
            decoration: const InputDecoration(
              hintText: 'Search by name or phone...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddCustomerSheet,
              icon: const Icon(Icons.person_add),
              label: const Text('New Customer'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final c = filteredCustomers[index];
              final selected = _selectedCustomer?.id == c.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: selected ? AppColors.primary : AppColors.primarySurface,
                  child: Text(
                    c.name[0].toUpperCase(),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(c.name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(c.phone ?? 'No phone'),
                trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                selected: selected,
                selectedTileColor: AppColors.primarySurface.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => setState(() => _selectedCustomer = c),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddCustomerSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Add Customer', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person_outline)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  try {
                    final dio = ref.read(dioClientProvider);
                    final resp = await dio.post(ApiEndpoints.customers, data: {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                    });
                    final newCustomer = CustomerModel.fromJson(resp.data);
                    setState(() {
                      _customers.insert(0, newCustomer);
                      _selectedCustomer = newCustomer;
                    });
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Add & Select'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === STEP 2: Product Selection ===
  Widget _buildStep2ProductSelection() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final qty = _quantities[product.id] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: qty > 0 ? AppColors.primarySurface.withValues(alpha: 0.3) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: qty > 0 ? AppColors.primary : AppColors.cardBorder,
                    width: qty > 0 ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(product.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(product.unitPrice),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (product.hasSecurityDeposit)
                            Text(
                              '+ ${CurrencyFormatter.format(product.securityDeposit)} deposit',
                              style: const TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                        ],
                      ),
                    ),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            onPressed: qty > 0
                                ? () => setState(() {
                                    if (qty == 1) {
                                      _quantities.remove(product.id);
                                    } else {
                                      _quantities[product.id] = qty - 1;
                                    }
                                  })
                                : null,
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            onPressed: () => setState(() => _quantities[product.id] = qty + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Running total
        if (_quantities.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_quantities.values.fold(0, (a, b) => a + b)} items',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  CurrencyFormatter.format(_subtotal),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // === STEP 3: Payment & Confirm ===
  Widget _buildStep3Payment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Customer: ${_selectedCustomer?.name}', style: const TextStyle(color: AppColors.textSecondary)),
                const Divider(height: 16),
                ..._items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.productName} ×${item.quantity}', style: const TextStyle(fontSize: 13))),
                      Text(CurrencyFormatter.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const Divider(height: 16),
                _summaryRow('Subtotal', CurrencyFormatter.format(_subtotal)),
                _summaryRow('Discount', '-${CurrencyFormatter.format(_discount)}'),
                const SizedBox(height: 4),
                _summaryRow(
                  'TOTAL',
                  CurrencyFormatter.format(_totalAmount),
                  isBold: true,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Discount
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Discount (PKR)',
              prefixIcon: Icon(Icons.discount_outlined),
            ),
            onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),

          // Payment method
          Text('Payment Method', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PaymentMethodChip(label: 'Cash', value: 'cash', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
              _PaymentMethodChip(label: 'Bank Transfer', value: 'bank_transfer', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
              _PaymentMethodChip(label: 'EasyPaisa', value: 'easypaisa', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
              _PaymentMethodChip(label: 'JazzCash', value: 'jazzcash', selected: _paymentMethod, onTap: (v) => setState(() => _paymentMethod = v)),
              _PaymentMethodChip(label: 'Credit', value: 'credit', selected: _paymentMethod, onTap: (v) => setState(() { _paymentMethod = v; _paymentStatus = 'pending'; })),
            ],
          ),
          const SizedBox(height: 16),

          // Payment status
          Text('Payment Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Paid'), selected: _paymentStatus == 'paid',
                onSelected: (_) => setState(() => _paymentStatus = 'paid'),
                selectedColor: AppColors.successLight,
              ),
              ChoiceChip(label: const Text('Partial'), selected: _paymentStatus == 'partial',
                onSelected: (_) => setState(() => _paymentStatus = 'partial'),
                selectedColor: AppColors.warningLight,
              ),
              ChoiceChip(label: const Text('Pending'), selected: _paymentStatus == 'pending',
                onSelected: (_) => setState(() => _paymentStatus = 'pending'),
                selectedColor: AppColors.dangerLight,
              ),
            ],
          ),

          if (_paymentStatus == 'partial') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (PKR)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              onChanged: (v) => setState(() => _amountPaid = double.tryParse(v) ?? 0),
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color ?? AppColors.textPrimary,
          )),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
            color: color ?? AppColors.textPrimary,
          )),
        ],
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

