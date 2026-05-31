import 'package:flutter/material.dart';

class ContentSections extends StatelessWidget {
  final List<SectionData> sections;

  const ContentSections({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 768;
    final contentWidth = width >= 768 ? 900.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 CONTENT BLOCK (NO EXTRA VERTICAL GAP)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, // ✅ SAME for all screens
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 🔥 TITLE + SUBTITLE
                      isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(section.icon, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            section.subtitle,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Icon(section.icon, color: Colors.blue),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              section.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Text(
                            section.subtitle,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// 🔹 CONTENT
                      Text(
                        section.content,
                        style: TextStyle(
                          height: 1.6,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// 🔹 POINTS
                      ...section.points.map((point) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(point),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                /// 🔥 DIVIDER (OUTSIDE PADDING)
                if (index != sections.length - 1)
                  const Divider(height: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 🔹 DATA MODEL
class SectionData {
  final String title;
  final String subtitle;
  final String content;
  final List<String> points;
  final IconData icon;

  SectionData({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.points,
    required this.icon,
  });
}
