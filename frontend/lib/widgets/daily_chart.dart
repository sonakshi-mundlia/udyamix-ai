import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/dashboard_model.dart';
import 'kpi_content.dart';

class DailyDashboard extends StatelessWidget {
  final DashboardModel? dashboard;
  final DateTime selectedDate;

  const DailyDashboard({
    super.key,
    required this.dashboard,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (dashboard == null ||
            selectedDate.isBefore(dashboard!.date)) {
          return _buildEmptyState(context, isMobile, t);
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  _buildHeader(isMobile, t),

                  const SizedBox(height: 16),

                  /// KPI CONTENT
                  KPIContent(
                    dashboard: dashboard!,
                    viewType: t('daily_dashboard.daily'), // 🔥 localized
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// HEADER
  Widget _buildHeader(bool isMobile, Function t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// TITLE
        Text(
          t('daily_dashboard.daily_title'),
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        /// DATE CHIP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// EMPTY STATE
  Widget _buildEmptyState(BuildContext context, bool isMobile, Function t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: isMobile ? 60 : 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),

              Text(
                t('daily_dashboard.no_data_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                t('daily_dashboard.no_data_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isMobile ? 13 : 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
