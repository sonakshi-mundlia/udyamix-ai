import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/scroll_spy_widget.dart';
import '../widgets/content_widget.dart';
import '../widgets/cta_widget.dart';
import '../providers/language_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;
    final tList = langProvider.translateStringList;

    return ScrollSpyPage(
      pageTitle: t("terms.title"),

      titles: [
        t("terms.sections.eligibility.title"),
        t("terms.sections.ai_disclaimer.title"),
        t("terms.sections.subscription.title"),
        t("terms.sections.ip_rights.title"),
        t("terms.sections.termination.title"),
      ],

      sections: [

        /// 🔹 1. Eligibility
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.verified_user,
              title: t("terms.sections.eligibility.title"),
              subtitle: t("terms.sections.eligibility.subtitle"),
              content: t("terms.sections.eligibility.content"),
              points: tList("terms.sections.eligibility.points"),
            ),
          ],
        ),

        /// 🔹 2. AI Disclaimer
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.psychology,
              title: t("terms.sections.ai_disclaimer.title"),
              subtitle: t("terms.sections.ai_disclaimer.subtitle"),
              content: t("terms.sections.ai_disclaimer.content"),
              points: tList("terms.sections.ai_disclaimer.points"),
            ),
          ],
        ),

        /// 🔹 3. Subscription
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.subscriptions,
              title: t("terms.sections.subscription.title"),
              subtitle: t("terms.sections.subscription.subtitle"),
              content: t("terms.sections.subscription.content"),
              points: tList("terms.sections.subscription.points"),
            ),
          ],
        ),

        /// 🔹 4. IP Rights
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.copyright,
              title: t("terms.sections.ip_rights.title"),
              subtitle: t("terms.sections.ip_rights.subtitle"),
              content: t("terms.sections.ip_rights.content"),
              points: tList("terms.sections.ip_rights.points"),
            ),
          ],
        ),

        /// 🔹 5. Termination
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.cancel,
              title: t("terms.sections.termination.title"),
              subtitle: t("terms.sections.termination.subtitle"),
              content: t("terms.sections.termination.content"),
              points: tList("terms.sections.termination.points"),
            ),
          ],
        ),

        /// 🔥 FINAL CTA
        const CTASection(),
      ],
    );
  }
}