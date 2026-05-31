import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  FullDashboardModel? dashboardData;

  bool loading = false;
  bool error = false;

  DateTime selectedDate = DateTime.now();

  /// =========================================================
  /// LOAD DASHBOARD
  /// =========================================================
  Future<void> loadDashboard({DateTime? date}) async {
    loading = true;
    error = false;

    notifyListeners();

    try {
      selectedDate = date ?? selectedDate;

      dashboardData = await ApiService.getDashboard(
        date: selectedDate,
      );

      // DEBUG LOGS
      print("========== DASHBOARD ==========");

      print("DAILY SALES: ${dashboardData?.daily.sales}");
      print("WEEKLY SALES: ${dashboardData?.weekly.sales}");
      print("MONTHLY SALES: ${dashboardData?.monthly.sales}");
      print("TOTAL SALES: ${dashboardData?.total.sales}");

      print("DAILY TREND: ${dashboardData?.daily.salesTrend}");
      print("WEEKLY TREND: ${dashboardData?.weekly.salesTrend}");
      print("MONTHLY TREND: ${dashboardData?.monthly.salesTrend}");
      print("TOTAL TREND: ${dashboardData?.total.salesTrend}");

    } catch (e) {
      print("Error loading dashboard: $e");

      error = true;
    } finally {
      loading = false;

      notifyListeners();
    }
  }

  /// =========================================================
  /// REFRESH
  /// =========================================================
  Future<void> refresh() async {
    await loadDashboard();
  }

  /// =========================================================
  /// CHANGE DATE
  /// =========================================================
  void setDate(DateTime date) {
    selectedDate = date;

    loadDashboard(date: date);
  }

  /// =========================================================
  /// HELPERS
  /// =========================================================

  bool _hasTrend(List<double> trend) {
    return trend.any((e) => e > 0);
  }

  /// =========================================================
  /// ANY DATA
  /// =========================================================
  bool get hasAnyData {
    if (dashboardData == null) {
      return false;
    }

    final daily = dashboardData!.daily;
    final weekly = dashboardData!.weekly;
    final monthly = dashboardData!.monthly;
    final total = dashboardData!.total;

    return (

        // DAILY
        daily.sales > 0 ||
            daily.expenses > 0 ||

            // WEEKLY
            weekly.sales > 0 ||
            weekly.expenses > 0 ||

            // MONTHLY
            monthly.sales > 0 ||
            monthly.expenses > 0 ||

            // TOTAL
            total.sales > 0 ||
            total.expenses > 0 ||

            // TRENDS
            _hasTrend(daily.salesTrend) ||
            _hasTrend(daily.expensesTrend) ||

            _hasTrend(weekly.salesTrend) ||
            _hasTrend(weekly.expensesTrend) ||

            _hasTrend(monthly.salesTrend) ||
            _hasTrend(monthly.expensesTrend) ||

            _hasTrend(total.salesTrend) ||
            _hasTrend(total.expensesTrend)
    );
  }

  /// =========================================================
  /// HAS SALES
  /// =========================================================
  bool get hasSales {
    if (dashboardData == null) {
      return false;
    }

    final daily = dashboardData!.daily;
    final weekly = dashboardData!.weekly;
    final monthly = dashboardData!.monthly;
    final total = dashboardData!.total;

    return (
        daily.sales > 0 ||
            weekly.sales > 0 ||
            monthly.sales > 0 ||
            total.sales > 0 ||

            _hasTrend(daily.salesTrend) ||
            _hasTrend(weekly.salesTrend) ||
            _hasTrend(monthly.salesTrend) ||
            _hasTrend(total.salesTrend)
    );
  }

  /// =========================================================
  /// HAS EXPENSES
  /// =========================================================
  bool get hasExpenses {
    if (dashboardData == null) {
      return false;
    }

    final daily = dashboardData!.daily;
    final weekly = dashboardData!.weekly;
    final monthly = dashboardData!.monthly;
    final total = dashboardData!.total;

    return (
        daily.expenses > 0 ||
            weekly.expenses > 0 ||
            monthly.expenses > 0 ||
            total.expenses > 0 ||

            _hasTrend(daily.expensesTrend) ||
            _hasTrend(weekly.expensesTrend) ||
            _hasTrend(monthly.expensesTrend) ||
            _hasTrend(total.expensesTrend)
    );
  }

  /// =========================================================
  /// TOTAL HELPERS
  /// =========================================================

  double get totalSales {
    if (dashboardData == null) return 0;

    return dashboardData!.total.sales;
  }

  double get totalExpenses {
    if (dashboardData == null) return 0;

    return dashboardData!.total.expenses;
  }

  double get totalProfit {
    if (dashboardData == null) return 0;

    return dashboardData!.total.profit;
  }

  double get totalLoss {
    if (dashboardData == null) return 0;

    return dashboardData!.total.loss;
  }

  double get totalCashFlow {
    if (dashboardData == null) return 0;

    return dashboardData!.total.cashFlow;
  }
}