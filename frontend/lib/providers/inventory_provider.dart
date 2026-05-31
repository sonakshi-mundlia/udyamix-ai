import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _items = [];
  bool _loading = false;

  List<InventoryItem> get items => _items;
  bool get loading => _loading;

  /// ✅ SAFE FETCH (no stale data issue)
  Future<void> fetchInventory() async {
    _loading = true;
    notifyListeners();

    try {
      // 🔥 Clear old cache immediately to avoid UI mismatch
      _items = [];
      notifyListeners();

      final result = await ApiService.fetchInventoryList();

      // assign fresh data
      _items = result;
    } catch (e) {
      debugPrint("Inventory fetch error: $e");

      // safety fallback
      _items = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// ➕ ADD ITEM
  Future<void> addItem(InventoryItem item) async {
    try {
      await ApiService.addInventory(
        item.productName,
        item.brand ?? "",
        item.quantity,
        item.unit,
        item.stockQuantity,
        pricePerUnit: item.pricePerUnit ?? 0,
      );

      await fetchInventory();
    } catch (e) {
      debugPrint("Add item error: $e");
    }
  }

  /// ✏️ UPDATE ITEM
  Future<void> updateItem(String id, InventoryItem item) async {
    try {
      await ApiService.updateInventory(
        id,
        item.productName,
        item.brand ?? "",
        item.quantity,
        item.unit,
        item.stockQuantity,
        pricePerUnit: item.pricePerUnit ?? 0,
      );

      await fetchInventory();
    } catch (e) {
      debugPrint("Update item error: $e");
    }
  }

  /// ❌ DELETE ITEM
  Future<void> deleteItem(String id) async {
    try {
      await ApiService.deleteInventory(id);
      await fetchInventory();
    } catch (e) {
      debugPrint("Delete item error: $e");
    }
  }

  /// 🔥 HELPER (BEST PRACTICE)
  bool get hasInventory => _items.isNotEmpty && !_loading;

  void clear() {
    _items = [];
    _loading = false;
    notifyListeners();
  }
}