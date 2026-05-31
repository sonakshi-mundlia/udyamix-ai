import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/scroll_spy_widget.dart';
import '../widgets/content_widget.dart';
import '../widgets/cta_widget.dart';
import '../providers/language_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;
    final tList = lang.translateStringList;

    return ScrollSpyPage(
      pageTitle: t("privacy.title"),

      titles: [
        t("privacy.philosophy"),
        t("privacy.data_collection"),
        t("privacy.ai_protocol"),
        t("privacy.integrations"),
        t("privacy.data_rights"),
      ],

      sections: [

        /// 🔹 1. Philosophy
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.security,
              title: t("privacy.philosophy_title"),
              subtitle: t("privacy.philosophy_subtitle"),
              content: t("privacy.philosophy_content"),
              points: tList("privacy.philosophy_points"),
            ),
          ],
        ),

        /// 🔹 2. Data Collection
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.folder,
              title: t("privacy.data_collection_title"),
              subtitle: t("privacy.data_collection_subtitle"),
              content: t("privacy.data_collection_content"),
              points: tList("privacy.data_collection_points"),
            ),
          ],
        ),

        /// 🔹 3. AI Protocol
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.psychology,
              title: t("privacy.ai_protocol_title"),
              subtitle: t("privacy.ai_protocol_subtitle"),
              content: t("privacy.ai_protocol_content"),
              points: tList("privacy.ai_protocol_points"),
            ),
          ],
        ),

        /// 🔹 4. Integrations
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.link,
              title: t("privacy.integrations_title"),
              subtitle: t("privacy.integrations_subtitle"),
              content: t("privacy.integrations_content"),
              points: tList("privacy.integrations_points"),
            ),
          ],
        ),

        /// 🔹 5. Data Rights
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.privacy_tip,
              title: t("privacy.data_rights_title"),
              subtitle: t("privacy.data_rights_subtitle"),
              content: t("privacy.data_rights_content"),
              points: tList("privacy.data_rights_points"),
            ),
          ],
        ),

        /// 🔥 FINAL CTA
        const CTASection(),
      ],
    );
  }
}