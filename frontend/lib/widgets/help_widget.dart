import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class HelpSection extends StatelessWidget {
  final VoidCallback? onOpenChat;

  const HelpSection({super.key, this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          /// 🔹 TITLE
          Text(
            t('help_widget.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 12),

          /// 🔹 DESCRIPTION
          Text(
            t('help_widget.description'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          /// 🔹 BUTTON
          Material(
            color: Colors.transparent,
            child: SizedBox(
              width: isMobile ? double.infinity : 200,
              child: ElevatedButton.icon(
                onPressed: onOpenChat,
                icon: const Icon(Icons.smart_toy),
                label: Text(t('help_widget.button')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}