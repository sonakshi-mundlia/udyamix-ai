import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';

class HeroSection extends StatelessWidget {
  final GlobalKey featuresKey;
  const HeroSection({super.key, required this.featuresKey});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.translate;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// 🔹 TOP SECTION
              isMobile
                  ? Column(
                children: [
                  _image(),
                  const SizedBox(height: 20),
                  _content(context, isMobile, t),
                ],
              )
                  : Row(
                children: [
                  Expanded(child: _image()),
                  const SizedBox(width: 30),
                  Expanded(child: _content(context, isMobile, t)),
                ],
              ),

              const SizedBox(height: 24),

              /// 🔹 JOIN TEXT
              Text(
                t('hero.join_text'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 24),

              /// 🔹 BUTTONS
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: isMobile
                    ? WrapAlignment.center
                    : WrapAlignment.start,
                children: [
                  _blueButton(
                    label: t('hero.get_started'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),
                  _blueOutlinedButton(
                    label: t('hero.login'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      if (featuresKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          featuresKey.currentContext!,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(t('hero.explore_features')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// IMAGE
  Widget _image() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/business.jpg',
        fit: BoxFit.cover,
        height: 360,
        width: double.infinity,
      ),
    );
  }

  /// CONTENT
  Widget _content(BuildContext context, bool isMobile, Function t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          t('hero.title_line1'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          t('hero.title_line2'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          t('hero.description'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// BUTTONS
  Widget _blueButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _blueOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: Colors.blue),
          foregroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}