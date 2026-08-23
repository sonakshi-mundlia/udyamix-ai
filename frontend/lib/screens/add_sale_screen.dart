import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale_model.dart';
import '../providers/business_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _customerController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isPaid = true;
  bool _loading = false;

  /// Submit sale with translation support
  Future<void> _submitSale(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final businessProvider = context.read<BusinessProvider>();
    final businessId = businessProvider.businessId;

    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('sales.business_not_selected'))),
      );
      setState(() => _loading = false);
      return;
    }

    final sale = SaleCreate(
      amount: double.parse(_amountController.text),
      customerName: _customerController.text.isEmpty
          ? null
          : _customerController.text,
      category: _categoryController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      saleDate: DateTime.now(),
      isPaid: _isPaid,
    );

    try {
      await ApiService.addSale(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('sales.sale_added_success'))),
        );
        Navigator.pop(context, true);
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
    _customerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    String t(String key) => lang.translate(key);

    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 800 ? 16.0 : 24.0;
    const maxWidth = 600.0;
    final spacing = size.width < 400 ? 12.0 : 16.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(t('sales.add_sale'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _inputField(
                      controller: _amountController,
                      label: t('sales.amount'),
                      keyboard: TextInputType.number,
                      validator: (v) =>
                      v == null || v.isEmpty ? t('sales.amount_required') : null,
                    ),
                    SizedBox(height: spacing),
                    _inputField(
                      controller: _customerController,
                      label: t('sales.customer_name_optional'),
                    ),
                    SizedBox(height: spacing),
                    _inputField(
                      controller: _categoryController,
                      label: t('sales.category_name'),
                    ),
                    SizedBox(height: spacing),
                    _inputField(
                      controller: _descriptionController,
                      label: t('sales.description_optional'),
                      maxLines: 3,
                    ),
                    SizedBox(height: spacing),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('sales.payment_received')),
                      value: _isPaid,
                      onChanged: (val) => setState(() => _isPaid = val),
                    ),
                    SizedBox(height: spacing * 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _submitSale(lang),
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
                          t('sales.save_sale'),
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
