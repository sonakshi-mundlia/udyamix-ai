import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/scroll_spy_widget.dart';
import '../widgets/content_widget.dart';
import '../widgets/cta_widget.dart';
import '../providers/language_provider.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;
    final tList = langProvider.translateStringList;

    return ScrollSpyPage(
      pageTitle: t('security.title'),

      titles: [
        t('security.encryption'),
        t('security.access_control'),
        t('security.ocr_privacy'),
        t('security.infrastructure'),
      ],

      sections: [

        /// 🔹 1. Encryption
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.lock,
              title: t('security.encryptions.title'),
              subtitle: t('security.encryptions.subtitle'),
              content: t('security.encryptions.content'),
              points: tList('security.encryptions.points'),
            ),
          ],
        ),

        /// 🔹 2. Access Control
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.security,
              title: t('security.access.title'),
              subtitle: t('security.access.subtitle'),
              content: t('security.access.content'),
              points: tList('security.access.points'),

            ),
          ],
        ),

        /// 🔹 3. OCR Privacy
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.visibility_off,
              title: t('security.ocr.title'),
              subtitle: t('security.ocr.subtitle'),
              content: t('security.ocr.content'),
              points: tList('security.ocr.points'),
            ),
          ],
        ),

        /// 🔹 4. Infrastructure
        ContentSections(
          sections: [
            SectionData(
              icon: Icons.cloud,
              title: t('security.infrastructures.title'),
              subtitle: t('security.infrastructures.subtitle'),
              content: t('security.infrastructures.content'),
              points: tList('security.infrastructures.points'),
            ),
          ],
        ),

        /// 🔥 Final CTA
        const CTASection(),
      ],
    );
  }
}