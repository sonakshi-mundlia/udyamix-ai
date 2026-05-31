import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/scroll_spy_widget.dart';
import '../widgets/content_widget.dart';
import '../widgets/cta_widget.dart';
import '../providers/language_provider.dart';

class FeaturesScreen extends StatelessWidget {
  final int initialIndex;

  const FeaturesScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;
    final tList = lang.translateStringList;

    return ScrollSpyPage(
      initialIndex: initialIndex,
      pageTitle: t("features.title"),

      titles: [
        t("features.sales"),
        t("features.expenses"),
        t("features.inventory"),
        t("features.ai"),
        t("features.comparison"),
      ],

      sections: [

        /// 💰 SALES
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.attach_money,
              title: t("features.sales_title"),
              subtitle: t("features.sales_subtitle"),
              content: t("features.sales_content"),
              points: tList("features.sales_points"),
            ),
          ],
        ),

        /// 🧾 EXPENSES
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.receipt_long,
              title: t("features.expenses_title"),
              subtitle: t("features.expenses_subtitle"),
              content: t("features.expenses_content"),
              points: tList("features.expenses_points"), // ✅ List
            ),
          ],
        ),

        /// 📦 INVENTORY
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.inventory,
              title: t("features.inventory_title"),
              subtitle: t("features.inventory_subtitle"),
              content: t("features.inventory_content"),
              points: tList("features.inventory_points"), // ✅ List
            ),
          ],
        ),

        /// 🤖 AI
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.psychology,
              title: t("features.ai_title"),
              subtitle: t("features.ai_subtitle"),
              content: t("features.ai_content"),
              points: tList("features.ai_points"), // ✅ List
            ),
          ],
        ),

        /// ⚖️ COMPARISON
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.compare,
              title: t("features.comparison_title"),
              subtitle: t("features.comparison_subtitle"),
              content: t("features.comparison_content"),
              points: tList("features.comparison_points"), // ✅ List
            ),
          ],
        ),

        const CTASection(),
      ],
    );
  }
}