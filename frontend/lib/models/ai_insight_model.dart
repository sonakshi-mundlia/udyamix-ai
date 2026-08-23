class Metric {
  final String name;
  final double? currentValue;
  final double? previousValue;
  final double? changeValue;
  final double? changePercentage;
  final String trend;

  Metric({
    required this.name,
    this.currentValue,
    this.previousValue,
    this.changeValue,
    this.changePercentage,
    required this.trend,
  });

  factory Metric.fromJson(Map<String, dynamic> json) {
    return Metric(
      name: json['name']?.toString() ?? '',
      currentValue: (json['current_value'] as num?)?.toDouble(),
      previousValue: (json['previous_value'] as num?)?.toDouble(),
      changeValue: (json['change_value'] as num?)?.toDouble(),
      changePercentage:
      (json['change_percentage'] as num?)?.toDouble(),
      trend: json['trend']?.toString() ?? 'not_comparable',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'current_value': currentValue,
    'previous_value': previousValue,
    'change_value': changeValue,
    'change_percentage': changePercentage,
    'trend': trend,
  };
}


class Urgency {
  final String level;
  final String reason;

  Urgency({
    required this.level,
    required this.reason,
  });

  factory Urgency.fromJson(Map<String, dynamic> json) {
    return Urgency(
      level: json['level']?.toString() ?? 'low',
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'reason': reason,
  };
}


class RootCause {
  final String primary;
  final List<String> possibleCauses;
  final List<String> evidence;
  final double confidence;

  RootCause({
    required this.primary,
    required this.possibleCauses,
    required this.evidence,
    required this.confidence,
  });

  factory RootCause.fromJson(Map<String, dynamic> json) {
    return RootCause(
      primary:
      json['primary']?.toString() ??
          'Not identified',

      possibleCauses:
      json['possible_causes'] is List
          ? List<String>.from(
        json['possible_causes'].map(
              (e) => e.toString(),
        ),
      )
          : [],

      evidence:
      json['evidence'] is List
          ? List<String>.from(
        json['evidence'].map(
              (e) => e.toString(),
        ),
      )
          : [],

      confidence:
      (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'primary': primary,
    'possible_causes': possibleCauses,
    'evidence': evidence,
    'confidence': confidence,
  };
}


class Impact {
  final double? financialValue;
  final double? estimatedRevenueLoss;
  final bool financialImpactAvailable;
  final String financialImpactReason;
  final String customerImpact;
  final String businessRisk;

  Impact({
    this.financialValue,
    this.estimatedRevenueLoss,
    required this.financialImpactAvailable,
    required this.financialImpactReason,
    required this.customerImpact,
    required this.businessRisk,
  });

  factory Impact.fromJson(Map<String, dynamic> json) {
    return Impact(
      financialValue:
      (json['financial_value'] as num?)?.toDouble(),

      estimatedRevenueLoss:
      (json['estimated_revenue_loss'] as num?)?.toDouble(),

      financialImpactAvailable:
      json['financial_impact_available'] ?? false,

      financialImpactReason:
      json['financial_impact_reason']?.toString() ?? '',

      customerImpact:
      json['customer_impact']?.toString() ?? '',

      businessRisk:
      json['business_risk']?.toString() ?? 'low',
    );
  }

  Map<String, dynamic> toJson() => {
    'financial_value': financialValue,
    'estimated_revenue_loss': estimatedRevenueLoss,
    'financial_impact_available':
    financialImpactAvailable,
    'financial_impact_reason':
    financialImpactReason,
    'customer_impact': customerImpact,
    'business_risk': businessRisk,
  };
}


class Formula {
  final String name;
  final String expression;
  final String calculation;
  final String result;

  Formula({
    required this.name,
    required this.expression,
    required this.calculation,
    required this.result,
  });

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      name: json['name']?.toString() ?? '',
      expression: json['expression']?.toString() ?? '',
      calculation: json['calculation']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'expression': expression,
    'calculation': calculation,
    'result': result,
  };
}


class Comparison {
  final double? previousPeriod;
  final double? currentPeriod;
  final double? difference;
  final double? percentageChange;

  Comparison({
    this.previousPeriod,
    this.currentPeriod,
    this.difference,
    this.percentageChange,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) {
    return Comparison(
      previousPeriod:
      (json['previous_period'] as num?)?.toDouble(),

      currentPeriod:
      (json['current_period'] as num?)?.toDouble(),

      difference:
      (json['difference'] as num?)?.toDouble(),

      percentageChange:
      (json['percentage_change'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'previous_period': previousPeriod,
    'current_period': currentPeriod,
    'difference': difference,
    'percentage_change': percentageChange,
  };
}


class Recommendation {
  final String priority;
  final List<String> immediateActions;
  final List<String> shortTermActions;
  final List<String> longTermActions;

  Recommendation({
    required this.priority,
    required this.immediateActions,
    required this.shortTermActions,
    required this.longTermActions,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      priority:
      json['priority']?.toString().toLowerCase() ?? 'low',

      immediateActions:
      json['immediate_actions'] is List
          ? List<String>.from(
        json['immediate_actions'].map(
              (e) => e.toString(),
        ),
      )
          : [],

      shortTermActions:
      json['short_term_actions'] is List
          ? List<String>.from(
        json['short_term_actions'].map(
              (e) => e.toString(),
        ),
      )
          : [],

      longTermActions:
      json['long_term_actions'] is List
          ? List<String>.from(
        json['long_term_actions'].map(
              (e) => e.toString(),
        ),
      )
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'priority': priority,
    'immediate_actions': immediateActions,
    'short_term_actions': shortTermActions,
    'long_term_actions': longTermActions,
  };
}


class ActionPlanItem {
  final int step;
  final String action;
  final String priority;

  ActionPlanItem({
    required this.step,
    required this.action,
    required this.priority,
  });

  factory ActionPlanItem.fromJson(
      Map<String, dynamic> json) {
    return ActionPlanItem(
      step: json['step'] ?? 0,
      action: json['action']?.toString() ?? '',
      priority:
      json['priority']?.toString().toLowerCase() ?? 'low',
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'action': action,
    'priority': priority,
  };
}


class ExtraData {
  final Metric metric;
  final Urgency urgency;
  final RootCause rootCause;
  final Impact impact;
  final Formula formula;
  final Comparison comparison;
  final Recommendation recommendation;
  final List<ActionPlanItem> actionPlan;
  final String expectedOutcome;
  final List<String> monitor;

  ExtraData({
    required this.metric,
    required this.urgency,
    required this.rootCause,
    required this.impact,
    required this.formula,
    required this.comparison,
    required this.recommendation,
    required this.actionPlan,
    required this.expectedOutcome,
    required this.monitor,
  });

  factory ExtraData.fromJson(
      Map<String, dynamic> json) {
    return ExtraData(
      metric: Metric.fromJson(
        Map<String, dynamic>.from(
          json['metric'] ?? {},
        ),
      ),

      urgency: Urgency.fromJson(
        Map<String, dynamic>.from(
          json['urgency'] ?? {},
        ),
      ),

      rootCause: RootCause.fromJson(
        Map<String, dynamic>.from(
          json['root_cause'] ?? {},
        ),
      ),

      impact: Impact.fromJson(
        Map<String, dynamic>.from(
          json['impact'] ?? {},
        ),
      ),

      formula: Formula.fromJson(
        Map<String, dynamic>.from(
          json['formula'] ?? {},
        ),
      ),

      comparison: Comparison.fromJson(
        Map<String, dynamic>.from(
          json['comparison'] ?? {},
        ),
      ),

      recommendation: Recommendation.fromJson(
        Map<String, dynamic>.from(
          json['recommendation'] ?? {},
        ),
      ),

      actionPlan:
      json['action_plan'] is List
          ? (json['action_plan'] as List)
          .map(
            (e) => ActionPlanItem.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList()
          : [],

      expectedOutcome:
      json['expected_outcome']?.toString() ?? '',

      monitor:
      json['monitor'] is List
          ? List<String>.from(
        json['monitor'].map(
              (e) => e.toString(),
        ),
      )
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'metric': metric.toJson(),
    'urgency': urgency.toJson(),
    'root_cause': rootCause.toJson(),
    'impact': impact.toJson(),
    'formula': formula.toJson(),
    'comparison': comparison.toJson(),
    'recommendation': recommendation.toJson(),
    'action_plan':
    actionPlan.map((e) => e.toJson()).toList(),
    'expected_outcome': expectedOutcome,
    'monitor': monitor,
  };
}


class AIInsightModel {
  final int? id;
  final int businessId;
  final String title;
  final String detail;
  final double score;
  final String language;
  final ExtraData extraData;
  final String? expandedDetail;

  AIInsightModel({
    this.id,
    required this.businessId,
    required this.title,
    required this.detail,
    required this.score,
    required this.language,
    required this.extraData,
    this.expandedDetail,
  });

  factory AIInsightModel.fromJson(
      Map<String, dynamic> json) {
    return AIInsightModel(
      id: json['id'] as int?,

      businessId:
      json['business_id'] ?? 0,

      title:
      json['title']?.toString() ??
          'Untitled',

      detail:
      json['detail']?.toString() ??
          'No details provided',

      score:
      (json['score'] as num?)?.toDouble() ??
          0.0,

      language:
      json['language']?.toString() ??
          'en',

      extraData:
      ExtraData.fromJson(
        Map<String, dynamic>.from(
          json['extra_data'] ?? {},
        ),
      ),

      expandedDetail:
      json['expanded_detail']?.toString(),
    );
  }

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