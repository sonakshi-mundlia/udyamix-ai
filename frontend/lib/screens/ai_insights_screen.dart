import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_insight_model.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {

  /// null = ALL insights
  String? _selectedWindow = '7';

  late Future<List<AIInsightModel>> _insightsFuture;

  @override
  void initState() {
    super.initState();

    /// Default = ALL insights
    _insightsFuture = _loadInsights('7');
  }

  Future<List<AIInsightModel>> _loadInsights(String? window) async {
    final lang = context.read<LanguageProvider>();

    try {
      final insights = await ApiService.fetchInsights(
        window: window ?? '7',
        lang: lang.currentLanguage,
      );
      return insights;
    } catch (e) {
      return [];
    }
  }

  void _onWindowSelected(String? window) {
    setState(() {
      _selectedWindow = window;
      _insightsFuture = _loadInsights(window);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    String t(String key) => lang.translate(key);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      appBar: AppBar(
        title: Text(t('ai_insights.title')),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [

                  _windowButton(
                    label: "All",
                    window: 'all',
                  ),

                  const SizedBox(width: 10),

                  _windowButton(
                    label: t('ai_insights.7_days'),
                    window: '7',
                  ),

                  const SizedBox(width: 10),

                  _windowButton(
                    label: t('ai_insights.30_days'),
                    window: '30',
                  ),
                ],
              ),
            ),
          ),

          /// INSIGHTS
          Expanded(
            child: FutureBuilder<List<AIInsightModel>>(
              future: _insightsFuture,

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {

                  return Center(
                    child: Text(
                      "${t('ai_insights.error_fetching')} : ${snapshot.error}",
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {

                  return Center(
                    child: Text(
                      t('ai_insights.no_insights'),
                    ),
                  );
                }

                final insights = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),

                  itemCount: insights.length,

                  itemBuilder: (context, index) {
                    return _buildInsightCard(
                      insights[index],
                      t,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowButton({
    required String label,
    required String? window,
  }) {

    final isSelected = _selectedWindow == window;

    return GestureDetector(
      onTap: () => _onWindowSelected(window),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : Colors.white,

          borderRadius: BorderRadius.circular(14),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
            ),
          ],
        ),

        child: Text(
          label,

          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.black,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      AIInsightModel insight,
      String Function(String) t,
      ) {

    final extra = insight.extraData;

    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {

        return Container(
          margin: const EdgeInsets.only(bottom: 16),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                /// TITLE
                Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),

                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        insight.title,

                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// DETAIL
                Text(
                  insight.detail,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 14),

                /// SCORE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  child: Text(
                    "${t('ai_insights.score')} : ${insight.score.toStringAsFixed(2)}",

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// EXTRA DATA
                _infoRow(
                  t('ai_insights.urgency'),
                  extra.urgency.level,
                ),

                _infoRow(
                  t('ai_insights.urgency_reason'),
                  extra.urgency.reason,
                ),

                _infoRow(
                  t('ai_insights.root_cause'),
                  extra.rootCause.primary,
                ),

                if (extra.rootCause.possibleCauses.isNotEmpty)
                  _infoRow(
                    t('ai_insights.possible_causes'),
                    extra.rootCause.possibleCauses.join(', '),
                  ),

                if (extra.rootCause.evidence.isNotEmpty)
                  _infoRow(
                    t('ai_insights.evidence'),
                    extra.rootCause.evidence.join(', '),
                  ),

                _infoRow(
                  t('ai_insights.confidence'),
                  '${(extra.rootCause.confidence * 100).toStringAsFixed(0)}%',
                ),

                _infoRow(
                  t('ai_insights.impact_value'),
                  extra.impact.financialValue?.toString() ?? 'Not available',
                ),

                _infoRow(
                  t('ai_insights.customer_impact'),
                  extra.impact.customerImpact.isEmpty
                      ? 'Not available'
                      : extra.impact.customerImpact,
                ),

                _infoRow(
                  t('ai_insights.business_risk'),
                  extra.impact.businessRisk,
                ),

                if (extra.impact.financialImpactReason.isNotEmpty)
                  _infoRow(
                    t('ai_insights.financial_impact_reason'),
                    extra.impact.financialImpactReason,
                  ),

                if (extra.formula.name.isNotEmpty)
                  _infoRow(
                    t('ai_insights.formula'),
                    extra.formula.result.isNotEmpty
                        ? extra.formula.result
                        : 'Not available',
                  ),

                if (extra.comparison.currentPeriod != null)
                  _infoRow(
                    t('ai_insights.current_period'),
                    extra.comparison.currentPeriod.toString(),
                  ),

                if (extra.comparison.previousPeriod != null)
                  _infoRow(
                    t('ai_insights.previous_period'),
                    extra.comparison.previousPeriod.toString(),
                  ),

                if (extra.comparison.difference != null)
                  _infoRow(
                    t('ai_insights.difference'),
                    extra.comparison.difference.toString(),
                  ),

                if (extra.comparison.percentageChange != null)
                  _infoRow(
                    t('ai_insights.percentage_change'),
                    '${extra.comparison.percentageChange}%',
                  ),

                if (extra.recommendation.priority.isNotEmpty)
                  _infoRow(
                    t('ai_insights.recommendation_priority'),
                    extra.recommendation.priority,
                  ),

                /// ACTION PLAN
                if (extra.actionPlan.isNotEmpty) ...[
                  const SizedBox(height: 12),

                  Text(
                    t('ai_insights.action_plan'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...extra.actionPlan.map(
                        (step) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 6,
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${step.step}. ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          Expanded(
                            child: Text(
                              step.action,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                /// EXPANDABLE ANALYSIS
                if (insight.expandedDetail != null &&
                    insight.expandedDetail!
                        .isNotEmpty) ...[

                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: () {

                      setStateCard(() {
                        isExpanded = !isExpanded;
                      });
                    },

                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.end,

                      children: [

                        Text(
                          isExpanded
                              ? t('ai_insights.show_less')
                              : t('ai_insights.read_detailed_analysis'),

                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 4),

                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,

                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  if (isExpanded)

                    Padding(
                      padding:
                      const EdgeInsets.only(top: 10),

                      child: Text(
                        insight.expandedDetail!,

                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            "$title : ",

            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
