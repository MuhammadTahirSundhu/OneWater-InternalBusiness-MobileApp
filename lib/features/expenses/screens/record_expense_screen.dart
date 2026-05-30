import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/models/expense_model.dart';
import '../../onboarding/providers/auth_provider.dart';

class RecordExpenseScreen extends ConsumerStatefulWidget {
  /// If [isAmountIn] is true, this form records an Amount In entry instead
  final bool isAmountIn;
  const RecordExpenseScreen({super.key, this.isAmountIn = false});

  @override
  ConsumerState<RecordExpenseScreen> createState() => _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'other';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioClientProvider);
      final endpoint = widget.isAmountIn ? ApiEndpoints.amountIn : ApiEndpoints.expenses;

      final body = widget.isAmountIn
          ? {
              'description': _descController.text.trim(),
              'amount': double.parse(_amountController.text),
              'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            }
          : {
              'description': _descController.text.trim(),
              'amount': double.parse(_amountController.text),
              'category': _selectedCategory,
              'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            };

      await dio.post(endpoint, data: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isAmountIn ? '✅ Amount In recorded!' : '✅ Expense recorded!'),
            backgroundColor: AppColors.success,
          ),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmountIn = widget.isAmountIn;
    final color = isAmountIn ? AppColors.success : AppColors.danger;
    final icon = isAmountIn ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final title = isAmountIn ? 'Record Amount In' : 'Record Expense';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 48),
                ),
              ),
              const SizedBox(height: 28),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: 'Rs. ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category (expense only)
              if (!isAmountIn) ...[
                Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseModel.allCategories.map((cat) {
                    final isSelected = _selectedCategory == cat['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : AppColors.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat['emoji']!, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              cat['label']!,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? color : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Notes (with "Other" description hint)
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _selectedCategory == 'other' ? 'Description / Notes *' : 'Notes (optional)',
                    prefixIcon: const Icon(Icons.note_outlined),
                    hintText: _selectedCategory == 'other' ? 'Describe what this expense is for...' : null,
                  ),
                  validator: _selectedCategory == 'other'
                      ? (v) => (v == null || v.trim().isEmpty) ? 'Please describe this expense' : null
                      : null,
                ),
              ] else ...[
                // Amount In — simple notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(icon),
                  label: Text(
                    _isSubmitting ? 'Saving...' : title,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
