import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class PrivacyWidget extends StatelessWidget {
  const PrivacyWidget({super.key});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _bullet(List<String> items) {
    return Column(
      children: items.map((text) {
        return Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;
    final tList = langProvider.translateStringList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔐 INTRO
        _sectionText(t('profile_privacy.intro')),

        _divider(),

        /// 📊 DATA COLLECTION
        _sectionTitle(t('profile_privacy.data_collection.title')),
        _sectionText(t('profile_privacy.data_collection.desc')),
        _bullet(tList('profile_privacy.data_collection.points')),
        _divider(),

        /// ⚙️ DATA USAGE
        _sectionTitle(t('profile_privacy.data_usage.title')),
        _sectionText(t('profile_privacy.data_usage.desc')),
        _bullet(tList('profile_privacy.data_usage.points')),

        _divider(),

        /// 🔒 SECURITY
        _sectionTitle(t('profile_privacy.security.title')),
        _sectionText(t('profile_privacy.security.desc')),
        _bullet(tList('profile_privacy.security.points')),

        _divider(),

        /// 👤 USER RIGHTS / CONTROL
        _sectionTitle(t('profile_privacy.user_control.title')),
        _sectionText(t('profile_privacy.user_control.desc')),
        _bullet(tList('profile_privacy.user_control.points')),

        _divider(),

        /// 🔁 DATA RETENTION
        _sectionTitle(t('profile_privacy.data_retention.title')),
        _sectionText(t('profile_privacy.data_retention.desc')),

        _divider(),

        /// 🌍 THIRD PARTY
        _sectionTitle(t('profile_privacy.third_party.title')),
        _sectionText(t('profile_privacy.third_party.desc')),

        _divider(),

        /// 📞 CONTACT
        _sectionTitle(t('profile_privacy.contact.title')),
        _sectionText(t('profile_privacy.contact.desc')),

        const SizedBox(height: 10),
      ],
    );
  }
}
