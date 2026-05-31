import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class FeaturesSection extends StatelessWidget {
  final GlobalKey featuresKey;

  const FeaturesSection({super.key, required this.featuresKey});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;
    final tList = lang.translateList;

    final features = tList('dashboard_features.items').map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else {
        // fallback for strings or unexpected types
        return {'title': item.toString(), 'desc': '', 'icon': 'star'};
      }
    }).toList();

    return Container(
      key: featuresKey,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 🔹 HEADING
          Text(
            t('dashboard_features.title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 SUBTITLE
          Text(
            t('dashboard_features.subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 40),

          /// 🔹 RESPONSIVE GRID
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 700;

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: List.generate(features.length, (index) {
                  final feature = features[index];

                  bool isAlternate = isMobile
                      ? index % 2 == 1
                      : ((index ~/ 2) % 2 == 0
                      ? index % 2 == 1
                      : index % 2 == 0);

                  return SizedBox(
                    width: isMobile
                        ? double.infinity
                        : (constraints.maxWidth / 2) - 20,
                    child: _FeatureCard(
                      title: feature['title'],
                      description: feature['desc'],
                      icon: _getIcon(feature['icon']),
                      isAlternate: isAlternate,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🔥 ICON MAPPER (STRING → ICON)
  IconData _getIcon(String name) {
    switch (name) {
      case "analytics":
        return Icons.analytics;
      case "wallet":
        return Icons.account_balance_wallet;
      case "chart":
        return Icons.show_chart;
      case "growth":
        return Icons.trending_up;
      case "lock":
        return Icons.lock;
      case "speed":
        return Icons.speed;
      default:
        return Icons.star;
    }
  }
}

/// 🔹 FEATURE CARD
class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isAlternate;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isAlternate,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
    isAlternate ? Colors.blue.shade100 : Colors.blue.shade50;

    final textColor =
    isAlternate ? Colors.blue.shade800 : Colors.blue.shade700;

    final iconColor =
    isAlternate ? Colors.blue.shade800 : Colors.blue.shade700;

    return Container(
      height: 150, // ✅ SAME SIZE FOR ALL
      padding: const EdgeInsets.all(20), // ✅ GOOD SPACING
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),

          const SizedBox(width: 16),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                /// LIMITED TEXT (NO OVERFLOW)
                Expanded(
                  child: Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withOpacity(0.9)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
