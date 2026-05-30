import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/customer_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../onboarding/providers/auth_provider.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/providers/connectivity_provider.dart';

final customersProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final cache = HiveCacheService();
  final isOnline = ref.read(isOnlineProvider);

  if (!isOnline) {
    final cached = cache.getList(ApiEndpoints.customers);
    if (cached != null) {
      return cached.map((e) => CustomerModel.fromJson(e)).toList();
    }
  }

  try {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(ApiEndpoints.customers);
    
    // Save to cache
    await cache.put(ApiEndpoints.customers, response.data, ttlMinutes: 1440); // 24 hours
    
    return (response.data as List).map((e) => CustomerModel.fromJson(e)).toList();
  } catch (e) {
    final cached = cache.getList(ApiEndpoints.customers);
    if (cached != null) {
      return cached.map((e) => CustomerModel.fromJson(e)).toList();
    }
    rethrow;
  }
});

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();
  bool _pendingOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _pendingOnly = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_pendingOnly ? AppColors.primarySurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !_pendingOnly ? AppColors.primary : AppColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: !_pendingOnly ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: !_pendingOnly ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _pendingOnly = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _pendingOnly ? AppColors.dangerLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _pendingOnly ? AppColors.danger : AppColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Has Pending',
                      style: TextStyle(
                        color: _pendingOnly ? AppColors.danger : AppColors.textSecondary,
                        fontWeight: _pendingOnly ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                var filtered = customers;
                if (_searchController.text.isNotEmpty) {
                  final q = _searchController.text.toLowerCase();
                  filtered = filtered.where((c) =>
                    c.name.toLowerCase().contains(q) ||
                    (c.phone?.contains(q) ?? false)
                  ).toList();
                }
                if (_pendingOnly) {
                  filtered = filtered.where((c) => c.hasPendingBalance).toList();
                }

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No customers found',
                    actionLabel: 'Add Customer',
                    onAction: () => context.push('/customers/new'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            c.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(c.phone ?? 'No phone', style: const TextStyle(fontSize: 13)),
                        trailing: c.hasPendingBalance
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  CurrencyFormatter.format(c.totalPending),
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () => context.push('/customers/${c.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/new'),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
