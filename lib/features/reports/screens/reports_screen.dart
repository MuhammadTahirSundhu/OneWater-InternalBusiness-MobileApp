import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(reportFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportSummaryProvider);
          ref.invalidate(salesByProductProvider);
          ref.invalidate(paymentStatusProvider);
          ref.invalidate(revenueTrendProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilterRow(context, ref, currentFilter),
              const SizedBox(height: 16),
              _buildSummaryCards(ref),
              const SizedBox(height: 24),
              _buildRevenueTrendChart(ref),
              const SizedBox(height: 24),
              _buildPaymentStatusChart(ref),
              const SizedBox(height: 24),
              _buildSalesByProductChart(ref),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterRow(BuildContext context, WidgetRef ref, ReportFilterState currentFilter) {
    final presets = [
      {'value': 'today', 'label': 'Today'},
      {'value': 'yesterday', 'label': 'Yesterday'},
      {'value': 'last_7_days', 'label': 'Last 7 Days'},
      {'value': 'this_month', 'label': 'This Month'},
      {'value': 'last_month', 'label': 'Last Month'},
      {'value': 'custom', 'label': 'Custom'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          final isSelected = p['value'] == currentFilter.preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () async {
                if (p['value'] == 'custom') {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    currentDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    ref.read(reportFilterProvider.notifier).state = ReportFilterState(
                      preset: 'custom',
                      dateFrom: picked.start,
                      dateTo: picked.end,
                    );
                  }
                } else {
                  ref.read(reportFilterProvider.notifier).state = ReportFilterState(preset: p['value']!);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  p['label']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider);

    return summaryAsync.when(
      data: (summary) => Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard('Today Sales', CurrencyFormatter.formatCompact(summary.todaySales), Icons.today, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard('MTD Sales', CurrencyFormatter.formatCompact(summary.monthSales), Icons.date_range, AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard('Total Pending', CurrencyFormatter.formatCompact(summary.totalPending), Icons.schedule, AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard('Pending Custs', '${summary.pendingCustomers}', Icons.people_outline, AppColors.danger)),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Text('Error loading summary'),
    );
  }

  Widget _buildRevenueTrendChart(WidgetRef ref) {
    final trendAsync = ref.watch(revenueTrendProvider);

    return _ChartCard(
      title: 'Revenue Trend',
      child: trendAsync.when(
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No data'));
          
          return SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= data.length || value.toInt() < 0) return const Text('');
                        final date = data[value.toInt()].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(date.substring(8, 10), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Text('Error loading chart'),
      ),
    );
  }

  Widget _buildPaymentStatusChart(WidgetRef ref) {
    final paymentAsync = ref.watch(paymentStatusProvider);

    return _ChartCard(
      title: 'Payment Status Breakdown',
      child: paymentAsync.when(
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No data'));

          return Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: data.map((d) {
                        Color color = AppColors.primary;
                        if (d.status == 'pending') color = AppColors.danger;
                        if (d.status == 'partial') color = AppColors.warning;
                        if (d.status == 'paid') color = AppColors.success;

                        return PieChartSectionData(
                          color: color,
                          value: d.amount,
                          title: '${d.percentage.toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((d) {
                    Color color = AppColors.primary;
                    if (d.status == 'pending') color = AppColors.danger;
                    if (d.status == 'partial') color = AppColors.warning;
                    if (d.status == 'paid') color = AppColors.success;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, color: color),
                          const SizedBox(width: 8),
                          Text('${d.status.toUpperCase()} (${d.count})', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text('Error loading chart: $error'),
      ),
    );
  }

  Widget _buildSalesByProductChart(WidgetRef ref) {
    final productsAsync = ref.watch(salesByProductProvider);

    return _ChartCard(
      title: 'Revenue by Product',
      child: productsAsync.when(
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No data'));

          return SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= data.length || value.toInt() < 0) return const Text('');
                        // Truncate long names
                        String name = data[value.toInt()].product;
                        if (name.length > 8) name = '${name.substring(0, 8)}...';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.revenue,
                        color: AppColors.primary,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Text('Error loading chart'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
