import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/product_model.dart';
import '../../onboarding/providers/auth_provider.dart';
import '../../../core/cache/hive_cache_service.dart';
import '../../../core/providers/connectivity_provider.dart';

final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final cache = HiveCacheService();
  final isOnline = ref.read(isOnlineProvider);

  if (!isOnline) {
    final cached = cache.getList(ApiEndpoints.products);
    if (cached != null) return cached.map((e) => ProductModel.fromJson(e)).toList();
  }

  try {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(ApiEndpoints.products);
    await cache.put(ApiEndpoints.products, response.data, ttlMinutes: 1440);
    return (response.data as List).map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    final cached = cache.getList(ApiEndpoints.products);
    if (cached != null) return cached.map((e) => ProductModel.fromJson(e)).toList();
    rethrow;
  }
});

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Products & Pricing')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('No products yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showProductSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Product'),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return _ProductCard(
                product: p,
                isAdmin: isAdmin,
                onEdit: () => _showProductSheet(context, ref, product: p),
                onToggle: (val) => _toggleProduct(context, ref, p, val),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showProductSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }

  Future<void> _toggleProduct(BuildContext context, WidgetRef ref, ProductModel p, bool val) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.put(ApiEndpoints.product(p.id), data: {'is_active': val});
      ref.invalidate(productsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showProductSheet(BuildContext context, WidgetRef ref, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(product: product, ref: ref),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isAdmin;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _ProductCard({required this.product, required this.isAdmin, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isAdmin ? onEdit : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(product.categoryDisplayName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('SKU: ${product.sku}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Tag(label: CurrencyFormatter.format(product.unitPrice), color: AppColors.primary),
                        if (product.hasSecurityDeposit) ...[
                          const SizedBox(width: 8),
                          _Tag(label: '+ ${CurrencyFormatter.format(product.securityDeposit)} dep.', color: AppColors.warning),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                Switch(
                  value: product.isActive,
                  onChanged: onToggle,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isActive ? AppColors.successLight : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      color: product.isActive ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

// ─── Product Form Sheet ───────────────────────────────────────────────────────
class _ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  final WidgetRef ref;
  const _ProductFormSheet({this.product, required this.ref});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _depositCtrl;
  String _selectedCategory = ProductModel.allCategories.first['value']!;
  bool _isSubmitting = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl    = TextEditingController(text: p?.name ?? '');
    _skuCtrl     = TextEditingController(text: p?.sku ?? '');
    _priceCtrl   = TextEditingController(text: p != null ? p.unitPrice.toStringAsFixed(0) : '');
    _depositCtrl = TextEditingController(text: p != null ? p.securityDeposit.toStringAsFixed(0) : '0');
    if (p != null) _selectedCategory = p.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _skuCtrl.dispose(); _priceCtrl.dispose(); _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final dio = widget.ref.read(dioClientProvider);
      final body = {
        'name': _nameCtrl.text.trim(),
        'sku': _skuCtrl.text.trim().toUpperCase(),
        'category': _selectedCategory,
        'unit_price': double.parse(_priceCtrl.text),
        'security_deposit': double.tryParse(_depositCtrl.text) ?? 0,
      };

      if (_isEditing) {
        await dio.put(ApiEndpoints.product(widget.product!.id), data: body);
      } else {
        await dio.post(ApiEndpoints.products, data: body);
      }

      widget.ref.invalidate(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '✅ Product updated!' : '✅ Product created!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(_isEditing ? 'Edit Product' : 'Add New Product',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.inventory_2_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _skuCtrl,
                decoration: const InputDecoration(labelText: 'SKU Code *', prefixIcon: Icon(Icons.qr_code)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined)),
                items: ProductModel.allCategories.map((cat) => DropdownMenuItem(
                  value: cat['value'],
                  child: Row(children: [
                    Text(cat['emoji']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(cat['label']!),
                  ]),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unit Price (PKR) *', prefixText: 'Rs. '),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depositCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Security Deposit', prefixText: 'Rs. '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(_isEditing ? 'Update Product' : 'Create Product',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
