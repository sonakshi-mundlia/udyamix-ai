import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/business_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isPaid = true;
  bool _loading = false;
  String? _selectedCategory;

  /// Static category keys (translation keys)
  final List<String> _categoryKeys = [
    "expenses.rent",
    "expenses.utilities",
    "expenses.transport",
    "expenses.food",
    "expenses.supplies",
    "expenses.salary",
    "expenses.other"
  ];

  /// Helper to submit expense
  Future<void> _submitExpense(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final businessProvider = context.read<BusinessProvider>();
    final businessId = businessProvider.businessId;

    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('expenses.business_not_selected'))),
      );
      setState(() => _loading = false);
      return;
    }

    final expense = ExpenseCreate(
      amount: double.parse(_amountController.text),
      vendorName: _vendorController.text.isEmpty
          ? null
          : _vendorController.text,
      category: _selectedCategory,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      expenseDate: DateTime.now(),
      isPaid: _isPaid,
    );

    try {
      await ApiService.addExpense(expense);

      await context.read<DashboardProvider>().refresh();

      await context.read<BusinessProvider>().loadBusinesses(
        email: context.read<UserProvider>().user!.email ?? "",
        mobile: context.read<UserProvider>().user!.mobile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('expenses.expense_added_success'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch LanguageProvider to rebuild when language changes
    final lang = context.watch<LanguageProvider>();
    String t(String key) => lang.translate(key);

    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 800 ? 16.0 : 24.0;
    const maxFormWidth = 600.0;
    final spacing = size.width < 400 ? 12.0 : 16.0;

    /// Get translated categories (rebuilds automatically when lang changes)
    final translatedCategories =
    _categoryKeys.map((c) => t(c)).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(t('expenses.add_expense'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxFormWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _inputField(
                      controller: _amountController,
                      label: t('expenses.amount'),
                      keyboard: TextInputType.number,
                      validator: (v) =>
                      v == null || v.isEmpty ? t('expenses.amount_required') : null,
                    ),
                    SizedBox(height: spacing),
                    _inputField(
                      controller: _vendorController,
                      label: t('expenses.vendor_name_optional'),
                    ),
                    SizedBox(height: spacing),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(t('expenses.category')),
                      items: translatedCategories
                          .map(
                            (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                    SizedBox(height: spacing),
                    _inputField(
                      controller: _descriptionController,
                      label: t('expenses.description_optional'),
                      maxLines: 3,
                    ),
                    SizedBox(height: spacing),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('expenses.payment_completed')),
                      value: _isPaid,
                      onChanged: (val) => setState(() => _isPaid = val),
                    ),
                    SizedBox(height: spacing * 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _submitExpense(lang),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          t('expenses.save_expense'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}