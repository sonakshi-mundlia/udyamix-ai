import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/inventory_model.dart';
import 'package:intl/intl.dart';

class InventoryWidget extends StatefulWidget {
  final InventoryItem? prefill;
  final List<InventoryItem> items;
  final Function(InventoryItem) onAdd;
  final Function(int, InventoryItem) onUpdate;
  final Function(int) onDelete;

  const InventoryWidget({
    super.key,
    this.prefill,
    this.items = const [],
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}


class _InventoryWidgetState extends State<InventoryWidget> {
  final _productController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(int stock) {
    if (stock <= 0) return "Out of Stock";
    if (stock <= 5) return "Low Stock";
    return "In Stock";
  }

  @override
  void initState() {
    super.initState();

    if (widget.prefill != null) {
      final item = widget.prefill!;
      _productController.text = item.productName;
      _brandController.text = item.brand ?? "";
      _quantityController.text = item.quantity.toString();
      _unitController.text = item.unit;
      _stockController.text = item.stockQuantity.toString();
      _priceController.text = item.pricePerUnit?.toString() ?? "";
    }
  }

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  void _showForm({InventoryItem? item, int? index}) {
    final t = context.read<LanguageProvider>().translate;

    if (item != null) {
      _productController.text = item.productName;
      _brandController.text = item.brand ?? "";
      _quantityController.text = item.quantity.toString();
      _unitController.text = item.unit;
      _stockController.text = item.stockQuantity.toString();
      _priceController.text = item.pricePerUnit?.toString() ?? '';
    } else {
      _productController.clear();
      _brandController.clear();
      _quantityController.clear();
      _unitController.clear();
      _stockController.clear();
      _priceController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          item != null
              ? t('inventories.update_inventory')
              : t('inventories.add_inventory'),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _productController,
                decoration: InputDecoration(
                  labelText: t('inventories.product_name'),
                ),
              ),
              TextField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: t('inventories.brand_name'),
                ),
              ),

              // SIZE (500ml / 1L)
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: "Quantity (500ml / 1L)",
                ),
              ),

              // STOCK (PACKS)
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock (No. of packs)",
                ),
              ),

              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t('inventories.price_per_unit'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final product = _productController.text.trim();
              final brand = _brandController.text.trim();
              final quantity = double.tryParse(_quantityController.text) ?? 0;
              final unit = _unitController.text.trim();
              final stock = int.tryParse(_stockController.text) ?? 0;
              final price = double.tryParse(_priceController.text) ?? 0;

              if (product.isEmpty) return;

              final newItem = InventoryItem(
                productName: product,
                brand: brand,
                quantity: quantity,
                unit: unit,
                stockQuantity: stock,
                pricePerUnit: price,
              );

              if (item != null && index != null) {
                widget.onUpdate(index, newItem);
              } else {
                widget.onAdd(newItem);
              }

              Navigator.pop(context);
            },
            child: Text(t('common.save')),
          ),
        ],
      ),
    );
  }

  void _showOptions(int index) {
    final t = context.read<LanguageProvider>().translate;

    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(t('common.update')),
            onTap: () {
              Navigator.pop(context);
              _showForm(item: widget.items[index], index: index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(t('common.delete')),
            onTap: () {
              widget.onDelete(index);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return _dateFormat.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().translate;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    final padding = isMobile ? 12.0 : 24.0;
    final containerWidth = isMobile
        ? (width - padding * 3) / 2
        : (width - padding * 5) / 4;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Wrap(
        spacing: padding,
        runSpacing: padding,
        children: [
          /// ➕ ADD CARD
          SizedBox(
            width: containerWidth,
            child: GestureDetector(
              onTap: () => _showForm(),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 40, color: Colors.blue),
                ),
              ),
            ),
          ),

          /// ITEMS
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return SizedBox(
              width: containerWidth,
              child: GestureDetector(
                onTap: () => _showOptions(index),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.productName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (item.brand != null && item.brand!.isNotEmpty)
                        Text(
                          item.brand!,
                          style: const TextStyle(color: Colors.grey),
                        ),

                      const SizedBox(height: 6),
                      Text(
                        item.quantity.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        item.unit,
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "₹ ${item.pricePerUnit?.toStringAsFixed(2) ?? '0.00'}",
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _getStockColor(item.stockQuantity).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getStockColor(item.stockQuantity),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStockText(item.stockQuantity),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStockColor(item.stockQuantity),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (item.createdAt != null)
                        Text(
                          "Added: ${_formatDateTime(item.createdAt)}",
                          style: const TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
