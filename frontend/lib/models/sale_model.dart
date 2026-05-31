class SaleCreate {
  final double amount;
  final String? customerName;
  final String? category;
  final String? description;
  final DateTime saleDate;
  final bool isPaid;

  SaleCreate({
    required this.amount,
    this.customerName,
    this.category,
    this.description,
    required this.saleDate,
    required this.isPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'customer_name': customerName,
      'category': category,
      'description': description,
      'sale_date': saleDate.toIso8601String().split('T')[0], // ✅ FIXED
      'is_paid': isPaid,
    };
  }
}
class Sale {
  final int id;
  final int businessId;
  final double amount;
  final String? customerName;
  final String? category;
  final String? description;
  final DateTime saleDate;
  final bool isPaid;

  Sale({
    required this.id,
    required this.businessId,
    required this.amount,
    this.customerName,
    this.category,
    this.description,
    required this.saleDate,
    required this.isPaid,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      businessId: json['business_id'],
      amount: (json['amount'] as num).toDouble(),
      customerName: json['customer_name'],
      category: json['category'],
      description: json['description'],
      saleDate: DateTime.parse(json['sale_date']),
      isPaid: json['is_paid'] ?? false,
    );
  }
}