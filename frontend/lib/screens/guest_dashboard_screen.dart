import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/hero_section_widget.dart';
import '../widgets/analyze_guide.dart';
import '../widgets/faq_widget.dart';
import '../widgets/features_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/chatbot_wrapper.dart';

import '../providers/language_provider.dart';

// 🔹 Screens
import '../screens/about_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/security_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/help_screen.dart';

class GuestDashboardScreen extends StatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  State<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends State<GuestDashboardScreen> {
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey<ChatbotWrapperState> _chatKey = GlobalKey();

  void openChat() {
    print("✅ openChat called");
    _chatKey.currentState?.openChat();
  }

  void _navigate(Widget screen) {
    print("➡️ Navigating to ${screen.runtimeType}");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;

    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔹 DRAWER
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Container(
                color: Colors.blue,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t("menu.title"), // localized
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        print("❌ Drawer closed");
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              _drawerItem(t("menu.about"), () {
                Navigator.pop(context);
                _navigate(const AboutScreen());
              }),
              _drawerItem(t("menu.privacy"), () {
                Navigator.pop(context);
                _navigate(const PrivacyScreen());
              }),
              _drawerItem(t("menu.security"), () {
                Navigator.pop(context);
                _navigate(const SecurityScreen());
              }),
              _drawerItem(t("menu.terms"), () {
                Navigator.pop(context);
                _navigate(const TermsScreen());
              }),
              _drawerItem(t("menu.help_center"), () {
                Navigator.pop(context);
                _navigate(const HelpScreen());
              }),
            ],
          ),
        ),
      ),

      /// 🔥 BODY
      body: ChatbotWrapper(
        key: _chatKey,
        showFloatingButton: true, // 👈 dashboard mode

        child: Column(
          children: [
            /// 🔹 NAVBAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t("app.title"), // localized
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),

                  Row(
                    children: [
                      /// 🔹 LANGUAGE DROPDOWN
                      Consumer<LanguageProvider>(
                        builder: (context, languageProvider, _) {
                          return PopupMenuButton<String>(
                            icon: const Icon(Icons.language, color: Colors.blue),

                            onSelected: (value) {
                              context.read<LanguageProvider>().loadLanguage(value);
                            },

                            itemBuilder: (context) {
                              return languageProvider.supportedLanguages.map((lang) {
                                return PopupMenuItem(
                                  value: lang,
                                  child: Text(
                                    lang.toUpperCase(),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList();
                            },
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      /// 🔹 MENU BUTTON
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.blue),
                          onPressed: () {
                            print("📂 Menu clicked");
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 🔹 CONTENT
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    HeroSection(featuresKey: _featuresKey),
                    const SizedBox(height: 30),
                    AnalyzeGuideSection(),
                    const SizedBox(height: 30),
                    FeaturesSection(featuresKey: _featuresKey),
                    const SizedBox(height: 30),
                    const FAQWidget(),
                    const SizedBox(height: 40),
                    const ProfessionalFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 DRAWER ITEM
  Widget _drawerItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      onTap: () {
        print("👉 Clicked: $title");
        onTap();
      },
    );
  }
}
