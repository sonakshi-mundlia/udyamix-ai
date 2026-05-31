class ExpenseCreate {
  final double amount;
  final String? category;
  final String? vendorName;
  final String? description;
  final DateTime expenseDate;
  final bool isPaid;

  ExpenseCreate({
    required this.amount,
    this.category,
    this.vendorName,
    this.description,
    required this.expenseDate,
    required this.isPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'vendor_name': vendorName,
      'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'is_paid': isPaid,
    };
  }
}
class Expense {
  final int id;
  final int businessId;
  final double amount;
  final String? category;
  final String? vendorName;
  final String? description;
  final DateTime expenseDate;
  final bool isPaid;

  Expense({
    required this.id,
    required this.businessId,
    required this.amount,
    this.category,
    this.vendorName,
    this.description,
    required this.expenseDate,
    required this.isPaid,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      businessId: json['business_id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      vendorName: json['vendor_name'],
      description: json['description'],
      expenseDate: DateTime.parse(json['expense_date']),
      isPaid: json['is_paid'] ?? false,
    );
  }
}