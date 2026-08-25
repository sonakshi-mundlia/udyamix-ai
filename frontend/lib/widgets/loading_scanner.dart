import 'package:flutter/material.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class OCRLoadingCard extends StatelessWidget {
  const OCRLoadingCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().translate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 52,
          ),

          const SizedBox(height: 16),

          Text(
            t('scanning_document'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            t('extracting_and_analyzing_your_document...'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          const LinearProgressIndicator(),

          const SizedBox(height: 12),

          Text(
            t('please_wait'),
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}