import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/scroll_spy_widget.dart';
import '../widgets/content_widget.dart';
import '../widgets/help_widget.dart';
import '../widgets/chatbot_wrapper.dart';
import '../providers/language_provider.dart';

class HelpScreen extends StatefulWidget {
  final int initialIndex;

  const HelpScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey<ChatbotWrapperState> _chatKey = GlobalKey();

  void openChat() {
    print("🔥 HelpScreen openChat called");
    _chatKey.currentState?.openChat();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;
    final tList = lang.translateStringList;

    return Scaffold(
      body: ChatbotWrapper(
        key: _chatKey,
        showFloatingButton: false, // ❌ no floating icon

        child: ScrollSpyPage(
          initialIndex: widget.initialIndex,
          pageTitle: t("help.title"),

          titles: [
            t("help.quick_start"),
            t("help.sales_expenses"),
            t("help.inventory"),
            t("help.ai_analyst"),
          ],

          sections: [
            /// QUICK START
            ContentSections(
              sections: [
                SectionData(
                  icon: Icons.rocket_launch,
                  title: t("help.quick_start_title"),
                  subtitle: t("help.quick_start_subtitle"),
                  content: t("help.quick_start_content"),
                  points: tList("help.quick_start_points"),
                ),
                SectionData(
                  icon: Icons.business,
                  title: t("help.step1_title"),
                  subtitle: t("help.step1_subtitle"),
                  content: t("help.step1_content"),
                  points: tList("help.step1_points"),
                ),
              ],
            ),

            /// SALES & EXPENSES
            ContentSections(
              sections: [
                SectionData(
                  icon: Icons.attach_money,
                  title: t("help.sales_expenses_title"),
                  subtitle: t("help.sales_expenses_subtitle"),
                  content: t("help.sales_expenses_content"),
                  points: tList("help.sales_expenses_points"),
                ),
              ],
            ),

            /// INVENTORY
            ContentSections(
              sections: [
                SectionData(
                  icon: Icons.inventory,
                  title: t("help.inventory_title"),
                  subtitle: t("help.inventory_subtitle"),
                  content: t("help.inventory_content"),
                  points: tList("help.inventory_points"),
                ),
              ],
            ),

            /// AI ANALYST
            ContentSections(
              sections: [
                SectionData(
                  icon: Icons.psychology,
                  title: t("help.ai_analyst_title"),
                  subtitle: t("help.ai_analyst_subtitle"),
                  content: t("help.ai_analyst_content"),
                  points: tList("help.ai_analyst_points"),
                ),
              ],
            ),

            /// HELP BUTTON
            HelpSection(
              onOpenChat: openChat,
            ),
          ],
        ),
      ),
    );
  }
}