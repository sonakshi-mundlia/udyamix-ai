class InventoryItem {
  final int? id;
  final int? businessId;
  final String productName;
  final String? brand;
  final double quantity;
  final String unit;
  final int stockQuantity;
  final double? pricePerUnit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryItem({
    this.id,
    this.businessId,
    required this.productName,
    this.brand,
    required this.quantity,
    required this.unit,
    required this.stockQuantity,
    this.pricePerUnit,
    this.createdAt,
    this.updatedAt,
  });

  String get stockInfo =>
      "$stockQuantity units of $quantity";

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      businessId: json['business_id'],
      productName: json['product_name'] ?? '',
      brand: json['brand'],
      quantity: json['quantity'] ?? '',
      unit: json['unit'],
      stockQuantity: json['stock_quantity'] ?? 0,

      pricePerUnit: json['price_per_unit'] != null
          ? (json['price_per_unit'] as num).toDouble()
          : null,

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "product_name": productName,
    "brand": brand,
    "quantity": quantity,
    "stock_quantity": stockQuantity,
    "price_per_unit": pricePerUnit,
  };

  InventoryItem copyWith({
    int? stockQuantity,
  }) {
    return InventoryItem(
      id: id,
      businessId: businessId,
      productName: productName,
      brand: brand,
      quantity: quantity,
      unit: unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      pricePerUnit: pricePerUnit,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}