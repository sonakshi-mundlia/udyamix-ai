// suggested_inventory_widget.dart
import 'package:flutter/material.dart';
import '../models/dashboard_background_model.dart';

class SuggestedInventoryWidget extends StatelessWidget {
  final List<SuggestedProductModel> suggestedItems;
  final void Function(SuggestedProductModel item) onItemTap;

  const SuggestedInventoryWidget({
    super.key,
    required this.suggestedItems,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double itemWidth = width < 400
        ? width / 2 - 24
        : width < 800
        ? width / 3 - 24
        : width / 4 - 24;

    if (suggestedItems.isEmpty) {
      return Center(
        child: Text(
          "All suggested items already added",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: suggestedItems.map((item) {
        return SizedBox(
          width: itemWidth,
          child: InkWell(
            onTap: () => onItemTap(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.productName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width < 400 ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.brand ?? " ",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: width < 400 ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
