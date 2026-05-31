import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/sale_model.dart';
import '../providers/language_provider.dart';
import '../providers/dashboard_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> sales = [];
  bool loading = true;
  bool showPaidOnly = false;
  bool showUnpaidOnly = false;

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  Future<void> refreshDashboard() async {
    if (!mounted) return;

    try {
      final dashboard = context.read<DashboardProvider>();
      await dashboard.loadDashboard();
    } catch (_) {}
  }

  Future<void> fetchSales() async {
    setState(() => loading = true);

    try {
      List<Sale> data;
      if (showPaidOnly) {
        data = await ApiService.getPaidSales();
      } else if (showUnpaidOnly) {
        data = await ApiService.getUnpaidSales();
      } else {
        data = await ApiService.listSales();
      }

      setState(() {
        sales = data;
        loading = false;
      });

      await refreshDashboard();

    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch sales: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('sale.title')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  showPaidOnly = false;
                  showUnpaidOnly = false;
                } else if (value == 'paid') {
                  showPaidOnly = true;
                  showUnpaidOnly = false;
                } else {
                  showPaidOnly = false;
                  showUnpaidOnly = true;
                }
              });

              fetchSales().then((_) {
                refreshDashboard();
              });
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'all', child: Text(t('sale.all_sales'))),
              PopupMenuItem(value: 'paid', child: Text(t('sale.paid_sales'))),
              PopupMenuItem(value: 'unpaid', child: Text(t('sale.unpaid_sales'))),
            ],
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : sales.isEmpty
          ? Center(child: Text(t('sale.no_sales')))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final sale = sales[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sale.isPaid ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sale.isPaid ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName ?? t('sale.unknown_customer'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text("${t('sale.amount')}: ₹${sale.amount}"),
                Text("${t('sale.category')}: ${sale.category ?? '-'}"),
                Text("${t('sale.date')}: ${sale.saleDate.toLocal().toString().split(' ')[0]}"),
                Text(
                  "${t('sale.status')}: ${sale.isPaid ? t('sale.paid') : t('sale.unpaid')}",
                  style: TextStyle(
                    color: sale.isPaid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}