import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';

class CTASection extends StatelessWidget {
  final String? title;
  final String? description;
  final String? primaryButtonText;
  final String? secondaryButtonText;

  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const CTASection({
    super.key,
    this.title,
    this.description,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimary,
    this.onSecondary,
  });

  void _goToRegister(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

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
            title ?? t('cta.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          /// 🔹 DESCRIPTION
          Text(
            description ?? t('cta.description'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          /// 🔥 RESPONSIVE BUTTONS
          isMobile
              ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  onPrimary ?? () => _goToRegister(context),
                  child: Text(primaryButtonText ?? t('cta.start')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                  onSecondary ?? () => _goToLogin(context),
                  child: Text(secondaryButtonText ?? t('cta.login')),
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed:
                onPrimary ?? () => _goToRegister(context),
                child: Text(primaryButtonText ?? t('cta.start')),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed:
                onSecondary ?? () => _goToLogin(context),
                child: Text(secondaryButtonText ?? t('cta.login')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



