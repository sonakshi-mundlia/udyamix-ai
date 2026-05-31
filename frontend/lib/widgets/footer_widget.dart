import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

// screens
import '../screens/about_screen.dart';
import '../screens/security_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/footer_features_screen.dart';
import '../screens/help_screen.dart';

class ProfessionalFooter extends StatelessWidget {
  const ProfessionalFooter({super.key});

  Widget _link(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  void _openFeatures(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeaturesScreen(initialIndex: index),
      ),
    );
  }

  void _helpCenter(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;
    final tList = lang.translateList;

    final offerItems = List<String>.from(tList('footer.offer'));
    final helpItems = List<String>.from(tList('footer.help'));

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      width: double.infinity,
      color: Colors.blue,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: isMobile ? 30 : 50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// MAIN CONTENT
                isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildSections(context, t, offerItems, helpItems, isMobile),
                )
                    : Wrap(
                  spacing: 40,
                  runSpacing: 30,
                  children: _buildSections(context, t, offerItems, helpItems, isMobile),
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.white24),

                const SizedBox(height: 15),

                /// COPYRIGHT
                Center(
                  child: Text(
                    t('footer.copyright'),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(
      BuildContext context,
      Function t,
      List<String> offerItems,
      List<String> helpItems,
      bool isMobile,
      ) {
    final sectionWidth = isMobile ? double.infinity : 220.0;

    return [
      /// BRAND
      SizedBox(
        width: isMobile ? double.infinity : 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Udyamix",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              t('footer.description'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),

      /// OFFER
      SizedBox(
        width: sectionWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(t('footer.offer_title')),
            ...offerItems.asMap().entries.map(
                  (entry) => _link(
                entry.value,
                    () => _openFeatures(context, entry.key),
              ),
            ),
          ],
        ),
      ),

      /// HELP
      SizedBox(
        width: sectionWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(t('footer.help_title')),
            ...helpItems.asMap().entries.map(
                  (entry) => _link(
                entry.value,
                    () => _helpCenter(context, entry.key),
              ),
            ),
          ],
        ),
      ),

      /// LEGAL
      SizedBox(
        width: sectionWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(t('footer.legal')),
            _link(t('footer.about'), () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()));
            }),
            _link(t('footer.privacy'), () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            }),
            _link(t('footer.terms'), () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()));
            }),
            _link(t('footer.security'), () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecurityScreen()));
            }),
          ],
        ),
      ),

      /// CONTACT
      SizedBox(
        width: sectionWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(t('footer.contact')),
            Text(t('footer.email'), style: const TextStyle(color: Colors.white70)),
            Text(t('footer.phone'), style: const TextStyle(color: Colors.white70)),
            Text(t('footer.location'), style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),

      /// SOCIAL
      SizedBox(
        width: sectionWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(t('footer.follow')),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.facebook, color: Colors.white),
                SizedBox(width: 12),
                Icon(Icons.link, color: Colors.white),
                SizedBox(width: 12),
                Icon(Icons.alternate_email, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}