class ExtraData {
  final String urgency;
  final String rootCause;
  final double impactValue;
  final String formula;
  final List<String> actionPlan;

  ExtraData({
    required this.urgency,
    required this.rootCause,
    required this.impactValue,
    required this.formula,
    required this.actionPlan,
  });

  factory ExtraData.fromJson(Map<String, dynamic> json) => ExtraData(
    urgency: json['urgency'] ?? "low",
    rootCause: json['root_cause'] ?? "Not identified",
    impactValue: (json['impact_value'] ?? 0).toDouble(),
    formula: json['formula'] ?? "",
    actionPlan: json['action_plan'] != null
        ? List<String>.from(json['action_plan'])
        : [],
  );

  Map<String, dynamic> toJson() => {
    'urgency': urgency,
    'root_cause': rootCause,
    'impact_value': impactValue,
    'formula': formula,
    'action_plan': actionPlan,
  };
}

class AIInsightModel {
  final int id;
  final int businessId;
  final String title;
  final String detail;
  final double score;
  final String language;
  final ExtraData extraData;
  final String? expandedDetail; // Optional long-form text (~500 words)

  AIInsightModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.detail,
    required this.score,
    required this.language,
    required this.extraData,
    this.expandedDetail,
  });

  factory AIInsightModel.fromJson(Map<String, dynamic> json) => AIInsightModel(
    id: json['id'] ?? 0,
    businessId: json['business_id'] ?? 0,
    title: json['title'] ?? "Untitled",
    detail: json['detail'] ?? "No details provided",
    score: (json['score'] ?? 0).toDouble(),
    language: json['language'] ?? "en",
    extraData: ExtraData.fromJson(
      Map<String, dynamic>.from(json['extra_data'] ?? {}),
    ),
    expandedDetail: json['expanded_detail'], // optional
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'title': title,
    'detail': detail,
    'score': score,
    'language': language,
    'extra_data': extraData.toJson(),
    'expanded_detail': expandedDetail,
  };
}