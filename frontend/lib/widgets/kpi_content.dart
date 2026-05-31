import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_model.dart';
import '../providers/language_provider.dart';

class KPIContent extends StatelessWidget {
  final DashboardModel dashboard;
  final String viewType;

  const KPIContent({
    super.key,
    required this.dashboard,
    this.viewType = "Daily",
  });

  List<double> _normalize(List<double> list) =>
      List.generate(7, (i) => i < list.length ? list[i] : 0);

  double _computeMaxY(List<double> salesTrend, List<double> expensesTrend) {
    final all = [
      ...salesTrend,
      ...expensesTrend,
      dashboard.sales,
      dashboard.expenses
    ];

    return (all.isEmpty ? 0 : all.reduce((a, b) => a > b ? a : b)) + 10;
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: "₹").format(value);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        /// 📱 Responsive
        int gridCount;
        double chartHeight;

        if (width < 600) {
          gridCount = 2;
          chartHeight = 180;
        } else if (width < 1000) {
          gridCount = 3;
          chartHeight = 220;
        } else {
          gridCount = 4;
          chartHeight = 260;
        }

        final sales = _normalize(dashboard.salesTrend);
        final expenses = _normalize(dashboard.expensesTrend);
        final maxY = _computeMaxY(sales, expenses);

        final days = t('kpi.days');

        return SingleChildScrollView(
          padding: EdgeInsets.all(width < 600 ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Text(
                "${t('kpi.dashboard')} - ${dashboard.date.day}/${dashboard.date.month}/${dashboard.date.year}",
                style: TextStyle(
                  fontSize: width < 600 ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// KPI GRID
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                children: [
                  _KPIItem(t('kpi.sales'), dashboard.sales, Colors.blue),
                  _KPIItem(t('kpi.expenses'), dashboard.expenses, Colors.red),
                  _KPIItem(t('kpi.cash_flow'), dashboard.cashFlow, Colors.teal),
                  _KPIItem(t('kpi.pending_cod'), dashboard.pendingCOD, Colors.orange),
                  _KPIItem(t('kpi.receivables'), dashboard.receivables, Colors.purple),
                  _KPIItem(
                    dashboard.profit != null
                        ? t('kpi.profit')
                        : t('kpi.loss'),
                    dashboard.profit ?? dashboard.loss ?? 0,
                    dashboard.profit != null ? Colors.green : Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _title(t('kpi.sales_vs_expenses_trend'), width),

              SizedBox(
                height: chartHeight,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            return Text(
                              days[v.toInt() % 7],
                              style: TextStyle(
                                fontSize: width < 600 ? 10 : 12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    lineBarsData: [
                      _line(sales, Colors.blue),
                      _line(expenses, Colors.red),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _title(t('kpi.sales_and_expenses'), width),

              SizedBox(
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: List.generate(
                      7,
                          (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(toY: sales[i], color: Colors.blue),
                          BarChartRodData(toY: expenses[i], color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (dashboard.expenseCategories.isNotEmpty) ...[
                _title(t('kpi.expense_breakdown'), width),

                SizedBox(
                  height: chartHeight,
                  child: PieChart(
                    PieChartData(
                      sections: dashboard.expenseCategories.entries.map((e) {
                        return PieChartSectionData(
                          value: e.value,
                          title: e.key,
                          color: Colors.primaries[
                          e.key.hashCode % Colors.primaries.length],
                          radius: width < 600 ? 40 : 50,
                          titleStyle: TextStyle(
                            color: Colors.white,
                            fontSize: width < 600 ? 10 : 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              _title(t('kpi.profit_ratio'), width),

              LinearProgressIndicator(
                value: dashboard.profit != null
                    ? (dashboard.profit! /
                    (dashboard.sales > 0 ? dashboard.sales : 1))
                    : 0,
                minHeight: width < 600 ? 10 : 14,
              ),

              const SizedBox(height: 24),

              _title(t('kpi.sales_vs_receivables'), width),

              SizedBox(
                height: chartHeight,
                child: ScatterChart(
                  ScatterChartData(
                    scatterSpots: [
                      ScatterSpot(
                        dashboard.sales.toDouble(),
                        dashboard.receivables.toDouble(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _title(t('kpi.rag_indicators'), width),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RAGIndicator(
                    t('kpi.sales'),
                    dashboard.sales,
                    5000,
                    2000,
                  ),
                  _RAGIndicator(
                    t('kpi.profit'),
                    dashboard.profit ?? 0,
                    1000,
                    500,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _title(String text, double width) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: width < 600 ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  LineChartBarData _line(List<double> data, Color color) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
            (i) => FlSpot(i.toDouble(), data[i]),
      ),
      color: color,
      isCurved: true,
      barWidth: 2,
    );
  }
}

/// KPI ITEM
class _KPIItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _KPIItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: "₹");

    return LayoutBuilder(
      builder: (context, c) {
        double w = c.maxWidth;

        return Container(
          padding: EdgeInsets.all(w < 120 ? 6 : 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w < 120 ? 10 : 13,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currency.format(value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w < 120 ? 12 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// RAG INDICATOR
class _RAGIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double green;
  final double yellow;

  const _RAGIndicator(this.label, this.value, this.green, this.yellow);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: "₹");

    Color color = value >= green
        ? Colors.green
        : (value >= yellow ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label: ${currency.format(value)}",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}