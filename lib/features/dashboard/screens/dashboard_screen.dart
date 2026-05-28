import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/payment_status_badge.dart';
import '../../../shared/models/transaction_model.dart';
import '../../onboarding/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final notifCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 70,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${AppDateUtils.getGreeting()}, ${user?.fullName.split(' ').first ?? ''}',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 26),
                      onPressed: () => context.push('/notifications'),
                    ),
                    notifCount.when(
                      data: (count) => count > 0
                          ? Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            // KPI Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                child: SizedBox(
                  height: 140,
                  child: dashboardAsync.when(
                    data: (data) => ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        StatCard(
                          title: AppStrings.todaySales,
                          value: CurrencyFormatter.formatCompact(data['today_sales'] ?? 0),
                          icon: Icons.trending_up,
                          iconColor: AppColors.success,
                          iconBgColor: AppColors.successLight,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: AppStrings.todayTransactions,
                          value: '${data['today_transactions'] ?? 0}',
                          icon: Icons.receipt_long,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: AppStrings.pendingPayments,
                          value: CurrencyFormatter.formatCompact(data['total_pending'] ?? 0),
                          icon: Icons.schedule,
                          iconColor: AppColors.warning,
                          iconBgColor: AppColors.warningLight,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: AppStrings.pendingCustomers,
                          value: '${data['pending_customers'] ?? 0}',
                          icon: Icons.people_outline,
                          iconColor: AppColors.danger,
                          iconBgColor: AppColors.dangerLight,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('Failed to load', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.receipt_long,
                            label: AppStrings.newSale,
                            color: AppColors.primary,
                            onTap: () => context.push('/transactions/new'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.person_add,
                            label: AppStrings.addCustomer,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => context.push('/customers/new'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.payments,
                            label: AppStrings.collectPayment,
                            color: AppColors.success,
                            onTap: () => context.push('/transactions'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.bar_chart,
                            label: AppStrings.viewReports,
                            color: AppColors.warning,
                            onTap: () {
                              if (user?.isAdminOrManager ?? false) {
                                context.push('/reports');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.recentTransactions,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
              ),
            ),

            // Transaction list
            recentAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No transactions yet.\nTap "New Sale" to get started!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final txn = TransactionModel.fromJson(transactions[index]);
                      return _TransactionTile(txn: txn);
                    },
                    childCount: transactions.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Failed to load transactions')),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;

  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/transactions/${txn.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${txn.invoiceNumber} · ${txn.itemsSummary}',
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
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PaymentStatusBadge(status: txn.paymentStatus),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
