// lib/models/dashboard_background_model.dart

class DashboardBackgroundModel {
  final String businessName;
  final List<SuggestedProductModel> data;
  final bool aiError;

  DashboardBackgroundModel({
    required this.businessName,
    required this.data,
    this.aiError = false,
  });

  factory DashboardBackgroundModel.fromJson(Map<String, dynamic> json) {
    return DashboardBackgroundModel(
      businessName: json['business_name'] ?? "",
      data: (json['data'] as List? ?? [])
          .map((item) => SuggestedProductModel.fromJson(item))
          .toList(),
      aiError: json['ai_error'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_name': businessName,
    'data': data.map((e) => e.toJson()).toList(),
    'ai_error': aiError,
  };
}

class SuggestedProductModel {
  final String productName;
  final String brand;

  SuggestedProductModel({
    required this.productName,
    required this.brand,
  });

  factory SuggestedProductModel.fromJson(Map<String, dynamic> json) {
    return SuggestedProductModel(
      productName: json['product_name'] ?? "",
      brand: json['brand'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'brand': brand,
  };
}