import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/scroll_spy_widget.dart';
import '../widgets/content_widget.dart';
import '../widgets/cta_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    String t(String key) => lang.translate(key);

    return ScrollSpyPage(
      pageTitle: t('about.page_title'),
      titles: [
        t('about.sections.executive_perspective.title'),
        t('about.sections.vision_mission.title'),
        t('about.sections.revenue_engine.title'),
        t('about.sections.finance_management.title'),
        t('about.sections.inventory_intelligence.title'),
        t('about.sections.market_intelligence.title'),
        t('about.sections.growth_system.title'),
        t('about.sections.values.title'),
        t('about.sections.roadmap.title'),
      ],

      sections: [

        /// 🔹 1. Executive Perspective
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.visibility,
              title: t('about.sections.executive_perspective.title'),
              subtitle: t('about.sections.executive_perspective.subtitle'),
              content: t('about.sections.executive_perspective.content'),
              points: List<String>.from(lang.translateList('about.sections.executive_perspective.points')),
            ),
          ],
        ),

        /// 🔹 2. Vision & Mission
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.flag,
              title: t('about.sections.vision_mission.title'),
              subtitle: t('about.sections.vision_mission.subtitle'),
              content: t('about.sections.vision_mission.content'),
              points: List<String>.from(lang.translateList('about.sections.vision_mission.points')),
            ),
          ],
        ),

        /// 🔹 3. Revenue Engine
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.trending_up,
              title: t('about.sections.revenue_engine.title'),
              subtitle: t('about.sections.revenue_engine.subtitle'),
              content: t('about.sections.revenue_engine.content'),
              points: List<String>.from(lang.translateList('about.sections.revenue_engine.points')),
            ),
          ],
        ),

        /// 🔹 4. Finance Management
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.account_balance_wallet,
              title: t('about.sections.finance_management.title'),
              subtitle: t('about.sections.finance_management.subtitle'),
              content: t('about.sections.finance_management.content'),
              points: List<String>.from(lang.translateList('about.sections.finance_management.points')),
            ),
          ],
        ),

        /// 🔹 5. Inventory Intelligence
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.inventory,
              title: t('about.sections.inventory_intelligence.title'),
              subtitle: t('about.sections.inventory_intelligence.subtitle'),
              content: t('about.sections.inventory_intelligence.content'),
              points: List<String>.from(lang.translateList('about.sections.inventory_intelligence.points')),
            ),
          ],
        ),

        /// 🔹 6. Market Intelligence
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.public,
              title: t('about.sections.market_intelligence.title'),
              subtitle: t('about.sections.market_intelligence.subtitle'),
              content: t('about.sections.market_intelligence.content'),
              points: List<String>.from(lang.translateList('about.sections.market_intelligence.points')),
            ),
          ],
        ),

        /// 🔹 7. Growth System
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.psychology,
              title: t('about.sections.growth_system.title'),
              subtitle: t('about.sections.growth_system.subtitle'),
              content: t('about.sections.growth_system.content'),
              points: List<String>.from(lang.translateList('about.sections.growth_system.points')),
            ),
          ],
        ),

        /// 🔹 8. Values
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.security,
              title: t('about.sections.values.title'),
              subtitle: t('about.sections.values.subtitle'),
              content: t('about.sections.values.content'),
              points: List<String>.from(lang.translateList('about.sections.values.points')),
            ),
          ],
        ),

        /// 🔹 9. Roadmap
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.rocket_launch,
              title: t('about.sections.roadmap.title'),
              subtitle: t('about.sections.roadmap.subtitle'),
              content: t('about.sections.roadmap.content'),
              points: List<String>.from(lang.translateList('about.sections.roadmap.points')),
            ),
          ],
        ),

        /// CTA Section
        const CTASection(),
      ],
    );
  }
}
