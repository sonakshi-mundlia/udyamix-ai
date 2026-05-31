import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_model.dart';
import '../providers/language_provider.dart';

class StockDashboardScreen extends StatelessWidget {
  const StockDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final lang = context.watch<LanguageProvider>();
    String t(String key) => lang.translate(key);

    if (provider.loading) {
      return Scaffold(
        body: Center(child: Text(t("common.loading"))),
      );
    }

    final items = provider.items;

    if (items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            t("stock.no_stock"),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;
    final isTablet = width > 700;

    final cardHeight = isTablet ? 120.0 : (isSmall ? 90.0 : 105.0);
    final gridCount = isTablet ? 4 : 2;

    /// =========================
    /// AI ENGINE
    /// =========================

    int salesRate(InventoryItem i) =>
        (i.stockQuantity * 0.6).toInt();

    bool isFast(InventoryItem i) => salesRate(i) > 5;
    bool isSlow(InventoryItem i) => salesRate(i) <= 5 && salesRate(i) > 2;
    bool isDead(InventoryItem i) => salesRate(i) == 0;

    bool needsReorder(InventoryItem i) {
      final demand = salesRate(i);
      return i.stockQuantity < demand * 2;
    }

    int daysLeft(InventoryItem i) {
      final demand = salesRate(i);
      if (demand == 0) return 999;
      return (i.stockQuantity / demand).round();
    }

    double profitScore(InventoryItem i) =>
        (i.pricePerUnit ?? 0) * salesRate(i);

    /// =========================
    /// ANALYTICS
    /// =========================

    final totalStock =
    items.fold<int>(0, (s, i) => s + i.stockQuantity);

    final totalValue =
    items.fold<double>(0, (s, i) => s + (i.stockQuantity * (i.pricePerUnit ?? 0)));

    final fastItems = items.where(isFast).toList();
    final slowItems = items.where(isSlow).toList();
    final deadItems = items.where(isDead).toList();
    final reorderItems = items.where(needsReorder).toList();

    final profitPerStock =
        totalValue / (totalStock == 0 ? 1 : totalStock);

    return Scaffold(
      appBar: AppBar(
        title: Text(t("stock.title")),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// TOP CARDS
            Row(
              children: [
                Expanded(
                  child: _topCard(
                    t("stock.total_stock"),
                    "$totalStock",
                    Colors.blue,
                    cardHeight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _topCard(
                    t("stock.total_value"),
                    "₹${totalValue.toStringAsFixed(0)}",
                    Colors.green,
                    cardHeight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _topCard(
                    t("stock.profit_per_stock"),
                    "₹${profitPerStock.toStringAsFixed(2)}",
                    Colors.purple,
                    cardHeight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: gridCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _statusCard(t("stock.fast"), fastItems.length, Colors.green),
                _statusCard(t("stock.slow"), slowItems.length, Colors.orange),
                _statusCard(t("stock.dead"), deadItems.length, Colors.red),
                _statusCard(t("stock.reorder"), reorderItems.length, Colors.purple),
              ],
            ),

            const SizedBox(height: 20),

            /// AI INSIGHTS TITLE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t("stock.ai_insights"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _aiTile(
              t("stock.fast_items"),
              t("stock.fast_desc"),
              fastItems.length,
              Colors.green,
            ),

            _aiTile(
              t("stock.slow_items"),
              t("stock.slow_desc"),
              slowItems.length,
              Colors.orange,
            ),

            _aiTile(
              t("stock.dead_items"),
              t("stock.dead_desc"),
              deadItems.length,
              Colors.red,
            ),

            _aiTile(
              t("stock.reorder_items"),
              t("stock.reorder_desc"),
              reorderItems.length,
              Colors.purple,
            ),

            const SizedBox(height: 20),

            /// ITEMS TITLE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t("stock.inventory_items"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...items.map((i) {
              final sales = salesRate(i);
              final days = daysLeft(i);
              final profit = profitScore(i);

              return _itemTile(i, sales, days, profit, t);
            }),
          ],
        ),
      ),
    );
  }

  /// ================= UI HELPERS =================

  Widget _topCard(String title, String value, Color color, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _statusCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text("$count",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _aiTile(String title, String desc, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text("$count",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _itemTile(
      InventoryItem item,
      int sales,
      int days,
      double profit,
      String Function(String) t,
      ) {
    final isFast = sales > 5;
    final isSlow = sales <= 5 && sales > 2;

    final color = isFast
        ? Colors.green
        : isSlow
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${t("stock.stock")}: ${item.stockQuantity} | ${t("stock.sales")}: $sales"),
                Text("${t("stock.days")}: $days | ${t("stock.profit")}: ₹${profit.toStringAsFixed(0)}"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}