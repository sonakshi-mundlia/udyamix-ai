import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import 'kpi_content.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class WeeklyDashboard extends StatelessWidget {
  final List<DashboardModel> dashboards;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyDashboard({
    super.key,
    required this.dashboards,
    required this.weekStart,
    required this.weekEnd,
  });

  /// -------------------------
  /// SAFE SUM HELPER
  /// -------------------------
  double _sum(List<DashboardModel> data, double Function(DashboardModel) getValue) {
    return data.fold<double>(0, (sum, item) => sum + getValue(item));
  }

  /// -------------------------
  /// AGGREGATE TREND
  /// -------------------------
  List<double> _aggregateTrend(List<List<double>> trends) {
    return trends.expand((e) => e).toList();
  }

  /// -------------------------
  /// AGGREGATE MAP (EXPENSE CATEGORIES)
  /// -------------------------
  Map<String, double> _aggregateMap(List<Map<String, double>> maps) {
    final result = <String, double>{};

    for (final map in maps) {
      map.forEach((key, value) {
        result[key] = (result[key] ?? 0) + value;
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;
    if (dashboards.isEmpty) {
      return Center(
        child: Text(
          "${t('weekly.no_data')} (${weekStart.day}/${weekStart.month} → ${weekEnd.day}/${weekEnd.month})",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    // -------------------------
    // TOTAL VALUES
    // -------------------------
    final totalSales = _sum(dashboards, (d) => d.sales);
    final totalExpenses = _sum(dashboards, (d) => d.expenses);
    final totalCashFlow = _sum(dashboards, (d) => d.cashFlow);
    final totalCOD = _sum(dashboards, (d) => d.pendingCOD);
    final totalReceivables = _sum(dashboards, (d) => d.receivables);

    // -------------------------
    // PROFIT / LOSS (SAFE)
    // -------------------------
    final hasProfit = dashboards.any((d) => d.profit != null);
    final hasLoss = dashboards.any((d) => d.loss != null);

    /// Aggregate, defaulting to 0.0 if none exist
    final totalProfit = _sum(dashboards, (d) => d.profit ?? 0.0);
    final totalLoss = _sum(dashboards, (d) => d.loss ?? 0.0);

    // -------------------------
    // TREND DATA
    // -------------------------
    final salesTrend =
    _aggregateTrend(dashboards.map((d) => d.salesTrend).toList());

    final expensesTrend =
    _aggregateTrend(dashboards.map((d) => d.expensesTrend).toList());

    // -------------------------
    // EXPENSE CATEGORIES
    // -------------------------
    final expenseCategories =
    _aggregateMap(dashboards.map((d) => d.expenseCategories).toList());

    // -------------------------
    // FINAL AGGREGATED MODEL
    // -------------------------
    final aggregated = DashboardModel(
      date: weekEnd,
      startDate: weekStart,
      sales: totalSales,
      expenses: totalExpenses,
      cashFlow: totalCashFlow,
      pendingCOD: totalCOD,
      receivables: totalReceivables,
      profit: totalProfit,
      loss: totalLoss,
      salesTrend: salesTrend,
      expensesTrend: expensesTrend,
      expenseCategories: expenseCategories,
    );

    return KPIContent(
      dashboard: aggregated,
      viewType: t('weekly.title'),
    );
  }
}
