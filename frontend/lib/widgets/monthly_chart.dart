import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_model.dart';
import '../providers/language_provider.dart';
import 'kpi_content.dart';

class MonthlyDashboard extends StatelessWidget {
  final List<DashboardModel> dashboards;
  final int month;
  final int year;

  const MonthlyDashboard({
    super.key,
    required this.dashboards,
    required this.month,
    required this.year,
  });

  /// Normalize trends safely
  List<double> _normalize(List<double> list) {
    if (list.length >= 7) return list.take(7).toList();
    return List.generate(7, (i) => i < list.length ? list[i] : 0);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;

    /// ❌ EMPTY STATE
    if (dashboards.isEmpty) {
      return Center(
        child: Text(
          "${t('monthly.no_data')} ($month/$year)",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    /// -------------------------
    /// AGGREGATE NUMBERS
    /// -------------------------
    final totalSales =
    dashboards.fold<double>(0.0, (s, d) => s + d.sales);

    final totalExpenses =
    dashboards.fold<double>(0.0, (s, d) => s + d.expenses);

    final totalCashFlow =
    dashboards.fold<double>(0.0, (s, d) => s + d.cashFlow);

    final totalCOD =
    dashboards.fold<double>(0.0, (s, d) => s + d.pendingCOD);

    final totalReceivables =
    dashboards.fold<double>(0.0, (s, d) => s + d.receivables);

    final totalProfit =
    dashboards.fold<double>(0.0, (s, d) => s + (d.profit ?? 0.0));

    final totalLoss =
    dashboards.fold<double>(0.0, (s, d) => s + (d.loss ?? 0.0));

    /// -------------------------
    /// AGGREGATE TRENDS
    /// (Flatten + normalize)
    /// -------------------------
    final aggregatedSalesTrend = _normalize(
      dashboards.expand((d) => d.salesTrend).toList(),
    );

    final aggregatedExpensesTrend = _normalize(
      dashboards.expand((d) => d.expensesTrend).toList(),
    );

    /// -------------------------
    /// AGGREGATE CATEGORIES
    /// -------------------------
    final Map<String, double> aggregatedExpenseCategories = {};

    for (var d in dashboards) {
      d.expenseCategories.forEach((k, v) {
        aggregatedExpenseCategories[k] =
            (aggregatedExpenseCategories[k] ?? 0) + v;
      });
    }

    /// -------------------------
    /// FINAL MODEL
    /// -------------------------
    final aggregated = DashboardModel(
      sales: totalSales,
      expenses: totalExpenses,
      cashFlow: totalCashFlow,
      profit: totalProfit,
      loss: totalLoss,
      pendingCOD: totalCOD,
      receivables: totalReceivables,
      salesTrend: aggregatedSalesTrend,
      expensesTrend: aggregatedExpensesTrend,
      expenseCategories: aggregatedExpenseCategories,
      date: DateTime(year, month),
      startDate: dashboards.first.startDate,
    );

    /// -------------------------
    /// UI
    /// -------------------------
    return KPIContent(
      dashboard: aggregated,
      viewType: t('monthly.title'), // 🔥 localized "Monthly"
    );
  }
}