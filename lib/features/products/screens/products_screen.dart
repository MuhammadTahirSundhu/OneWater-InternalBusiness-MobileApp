import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (cached != null) {
      return cached.map((e) => ProductModel.fromJson(e)).toList();
    }
  }

  try {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(ApiEndpoints.products);
    
    // Save to cache
    await cache.put(ApiEndpoints.products, response.data, ttlMinutes: 1440); // 24 hours
    
    return (response.data as List).map((e) => ProductModel.fromJson(e)).toList();
  } catch (e) {
    final cached = cache.getList(ApiEndpoints.products);
    if (cached != null) {
      return cached.map((e) => ProductModel.fromJson(e)).toList();
    }
    rethrow;
  }
});

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Products & Pricing')),
      body: productsAsync.when(
        data: (products) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('SKU: ${p.sku}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _PriceTag(label: 'Price', value: CurrencyFormatter.format(p.unitPrice)),
                                if (p.hasSecurityDeposit) ...[
                                  const SizedBox(width: 16),
                                  _PriceTag(label: 'Deposit', value: CurrencyFormatter.format(p.securityDeposit), color: AppColors.warning),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: p.isActive,
                        onChanged: (v) {},
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading products')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PriceTag({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? AppColors.primary)),
      ],
    );
  }
}
