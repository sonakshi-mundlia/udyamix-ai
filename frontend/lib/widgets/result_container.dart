import 'package:flutter/material.dart';
import '../models/ocr_result_model.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class OCRResultCard extends StatelessWidget {
  final OCRResultModel result;

  const OCRResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;
    final bool isSale =
        result.detectedType?.toLowerCase() == 'sale';

    final bool highConfidence =
        result.confidence >= 0.7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  t('document_processed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              _SourceTag(),
            ],
          ),

          const SizedBox(height: 20),

          _ResultRow(
            title: 'Type',
            value: isSale
                ? 'Sale'
                : 'Expense',
          ),

          _ResultRow(
            title: 'Amount',
            value:
            '₹${result.detectedAmount.toStringAsFixed(2)}',
          ),

          _ResultRow(
            title: isSale
                ? 'Customer'
                : 'Vendor',
            value:
            result.detectedParty ??
                'Not detected',
          ),

          _ResultRow(
            title: 'Category',
            value:
            result.detectedCategory ??
                'Not detected',
          ),

          _ResultRow(
            title: 'Date',
            value: result.detectedDate == null
                ? 'Not detected'
                : _formatDate(
              result.detectedDate!,
            ),
          ),

          _ResultRow(
            title: 'Confidence',
            value:
            '${(result.confidence * 100).toStringAsFixed(0)}%',
          ),

          const SizedBox(height: 12),

          if (highConfidence)
            _SuccessMessage(
              text: isSale
                  ? 'Added to Sales'
                  : 'Added to Expenses',
            )
          else
            const _WarningMessage(
              text:
              'Low confidence. Review before adding to financial records.',
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _ResultRow extends StatelessWidget {
  final String title;
  final String value;

  const _ResultRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade200,
      ),
      child: const Text(
        'OCR',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  final String text;

  const _SuccessMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '✓ $text',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WarningMessage extends StatelessWidget {
  final String text;

  const _WarningMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '⚠ $text',
      style: const TextStyle(
        fontWeight: FontWeight.w500,
      ),
    );
  }
}