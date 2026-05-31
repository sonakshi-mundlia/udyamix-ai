// lib/models/ocr_result_model.dart

class OCRResultModel {
  final String ocrId;
  final String detectedType; // sale or expense
  final double amount;
  final String? party; // customer/vendor
  final String? category;
  final String description;
  final String date; // YYYY-MM-DD
  final double confidence;
  final String language;

  OCRResultModel({
    required this.ocrId,
    required this.detectedType,
    required this.amount,
    this.party,
    this.category,
    required this.description,
    required this.date,
    required this.confidence,
    required this.language,
  });

  factory OCRResultModel.fromJson(Map<String, dynamic> json) {
    return OCRResultModel(
      ocrId: json['ocr_id'].toString(),
      detectedType: json['detected_type'],
      amount: (json['amount'] as num).toDouble(),
      party: json['party'],
      category: json['category'],
      description: json['description'],
      date: json['date'],
      confidence: (json['confidence'] as num).toDouble(),
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ocr_id': ocrId,
      'detected_type': detectedType,
      'amount': amount,
      'party': party,
      'category': category,
      'description': description,
      'date': date,
      'confidence': confidence,
      'language': language,
    };
  }
}