import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/expense_model.dart';
import '../providers/language_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> expenses = [];
  bool loading = true;
  bool showPaidOnly = false;
  bool showUnpaidOnly = false;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() => loading = true);

    try {
      List<Expense> data;
      if (showPaidOnly) {
        data = await ApiService.getPaidExpenses();
      } else if (showUnpaidOnly) {
        data = await ApiService.getUnpaidExpenses();
      } else {
        data = await ApiService.listExpenses();
      }

      setState(() {
        expenses = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      final t = Provider.of<LanguageProvider>(context, listen: false).translate;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t("expense.fetch_failed")}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    String t(String key) => lang.translate(key);

    return Scaffold(
      appBar: AppBar(
        title: Text(t("expense.title")),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'all') {
                showPaidOnly = false;
                showUnpaidOnly = false;
              } else if (value == 'paid') {
                showPaidOnly = true;
                showUnpaidOnly = false;
              } else if (value == 'unpaid') {
                showPaidOnly = false;
                showUnpaidOnly = true;
              }
              fetchExpenses();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'all', child: Text(t("expense.all"))),
              PopupMenuItem(
                  value: 'paid', child: Text(t("expense.paid"))),
              PopupMenuItem(
                  value: 'unpaid', child: Text(t("expense.unpaid"))),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
          ? Center(child: Text(t("expense.empty")))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final exp = expenses[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: exp.isPaid ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: exp.isPaid ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.vendorName ?? t("expense.vendor_name"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text("${t("expense.amount")}: ₹${exp.amount}"),
                Text("${t("expense.category")}: ${exp.category}"),
                Text(
                    "${t("expense.date")}: ${exp.expenseDate.toLocal().toString().split(' ')[0]}"),
                Text(
                  "${t("expense.status")}: ${exp.isPaid ? t("expense.paid") : t("expense.unpaid")}",
                  style: TextStyle(
                    color: exp.isPaid ? Colors.green : Colors.red,
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