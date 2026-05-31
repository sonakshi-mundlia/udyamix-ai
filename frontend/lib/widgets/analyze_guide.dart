import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AnalyzeGuideSection extends StatefulWidget {
  const AnalyzeGuideSection({super.key});

  @override
  State<AnalyzeGuideSection> createState() => _AnalyzeGuideSectionState();
}

class _AnalyzeGuideSectionState extends State<AnalyzeGuideSection> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tList = lang.translateList;

    /// ✅ FETCH FROM JSON
    final List<Map<String, dynamic>> steps =
    List<Map<String, dynamic>>.from(
      tList('analyze.steps'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1000;

        final horizontalPadding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 HEADER
              _buildHeaderImage(context, isMobile, isTablet),

              const SizedBox(height: 24),

              /// 🔥 STEPS LIST
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final isExpanded = expandedIndex == index;

                  return _StepCard(
                    step: step,
                    isExpanded: isExpanded,
                    onTap: () {
                      setState(() {
                        expandedIndex =
                        isExpanded ? null : index;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 HEADER IMAGE
  Widget _buildHeaderImage(
      BuildContext context, bool isMobile, bool isTablet) {
    final t = context.watch<LanguageProvider>().translate;

    double height = isMobile
        ? 180
        : isTablet
        ? 220
        : 280;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              "assets/images/dashboard1.jpg",
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// overlay
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),

        /// text
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('analyze.header.title'),
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t('analyze.header.subtitle'),
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final Map<String, dynamic> step; // ✅ FIXED
  final bool isExpanded;
  final VoidCallback onTap;

  const _StepCard({
    required this.step,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().translate;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TITLE
            Row(
              children: [
                Expanded(
                  child: Text(
                    step['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),

            /// 🔹 EXPAND
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(
                      title: t('analyze.points'),
                      items: List<String>.from(
                          step['steps'] ?? []),
                    ),
                    _Section(
                      title: t('analyze.purpose'),
                      items: List<String>.from(
                          step['purpose'] ?? []),
                    ),
                    _Section(
                      title: t('analyze.output'),
                      items: List<String>.from(
                          step['output'] ?? []),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> items;

  const _Section({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),

        /// 🔹 POINTS
        ...items.map(
              (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("• $e"),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}
