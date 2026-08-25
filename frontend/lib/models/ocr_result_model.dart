class OCRResultModel {
  final int id;
  final int documentId;
  final String? detectedType;
  final double detectedAmount;
  final String? detectedParty;
  final String? detectedCategory;
  final DateTime? detectedDate;
  final double confidence;
  final DateTime? createdAt;

  OCRResultModel({
    required this.id,
    required this.documentId,
    required this.detectedType,
    required this.detectedAmount,
    required this.detectedParty,
    required this.detectedCategory,
    required this.detectedDate,
    required this.confidence,
    required this.createdAt,
  });

  factory OCRResultModel.fromJson(Map<String, dynamic> json) {

    final ocr = Map<String, dynamic>.from(
      json['ocr_result'] ?? {},
    );

    return OCRResultModel(
      id: ocr['id'],
      documentId: ocr['document_id'],
      detectedType: ocr['detected_type'],
      detectedAmount: (ocr['detected_amount'] as num?)?.toDouble() ?? 0.0,
      detectedParty: ocr['detected_party'],
      detectedCategory: ocr['detected_category'],
      detectedDate: ocr['detected_date'] != null
          ? DateTime.tryParse(ocr['detected_date'].toString())
          : null,
      confidence: (ocr['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: ocr['created_at'] != null
          ? DateTime.tryParse(ocr['created_at'].toString())
          : null,
    );
  }
}