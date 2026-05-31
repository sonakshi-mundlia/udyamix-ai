class DashboardModel {
  // =========================================================
  // SUMMARY
  // =========================================================

  final double sales;
  final double expenses;
  final double cashFlow;
  final double profit;
  final double loss;

  // =========================================================
  // PENDING / RECEIVABLES
  // =========================================================

  final double pendingCOD;
  final double receivables;

  // =========================================================
  // TRENDS
  // =========================================================

  final List<double> salesTrend;
  final List<double> expensesTrend;

  // =========================================================
  // EXPENSE BREAKDOWN
  // =========================================================

  final Map<String, double> expenseCategories;

  // =========================================================
  // DATES
  // =========================================================

  final DateTime date;
  final DateTime startDate;

  DashboardModel({
    required this.sales,
    required this.expenses,
    required this.cashFlow,
    required this.profit,
    required this.loss,
    required this.pendingCOD,
    required this.receivables,
    required this.salesTrend,
    required this.expensesTrend,
    required this.expenseCategories,
    required this.date,
    required this.startDate,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      sales: (json['sales'] ?? 0).toDouble(),

      expenses: (json['expenses'] ?? 0).toDouble(),

      cashFlow: (json['cashFlow'] ?? 0).toDouble(),

      profit: (json['profit'] ?? 0).toDouble(),

      loss: (json['loss'] ?? 0).toDouble(),

      pendingCOD: (json['pendingCOD'] ?? 0).toDouble(),

      receivables: (json['receivables'] ?? 0).toDouble(),

      salesTrend: (json['salesTrend'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),

      expensesTrend: (json['expensesTrend'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),

      expenseCategories:
      (json['expenseCategories'] as Map<String, dynamic>? ?? {})
          .map(
            (k, v) => MapEntry(
          k,
          (v as num).toDouble(),
        ),
      ),

      date: DateTime.tryParse(
        json['date'] ?? '',
      ) ??
          DateTime.now(),

      startDate: DateTime.tryParse(
        json['startDate'] ?? '',
      ) ??
          DateTime.now().subtract(
            const Duration(days: 7),
          ),
    );
  }

  // =========================================================
  // EMPTY MODEL
  // =========================================================

  factory DashboardModel.empty() {
    return DashboardModel(
      sales: 0,
      expenses: 0,
      cashFlow: 0,
      profit: 0,
      loss: 0,
      pendingCOD: 0,
      receivables: 0,
      salesTrend: [],
      expensesTrend: [],
      expenseCategories: {},
      date: DateTime.now(),
      startDate: DateTime.now(),
    );
  }
}

class FullDashboardModel {

  // =========================================================
  // DASHBOARDS
  // =========================================================

  final DashboardModel daily;
  final DashboardModel weekly;
  final DashboardModel monthly;

  // ✅ NEW
  final DashboardModel total;

  FullDashboardModel({
    required this.daily,
    required this.weekly,
    required this.monthly,

    // ✅ NEW
    required this.total,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory FullDashboardModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return FullDashboardModel(
      daily: DashboardModel.fromJson(
        json['daily'] ?? {},
      ),

      weekly: DashboardModel.fromJson(
        json['weekly'] ?? {},
      ),

      monthly: DashboardModel.fromJson(
        json['monthly'] ?? {},
      ),

      // ✅ NEW
      total: DashboardModel.fromJson(
        json['total'] ?? {},
      ),
    );
  }

  // =========================================================
  // EMPTY MODEL
  // =========================================================

  factory FullDashboardModel.empty() {
    return FullDashboardModel(
      daily: DashboardModel.empty(),
      weekly: DashboardModel.empty(),
      monthly: DashboardModel.empty(),

      // ✅ NEW
      total: DashboardModel.empty(),
    );
  }
}