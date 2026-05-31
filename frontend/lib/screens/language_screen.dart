import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import 'guest_dashboard_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() =>
      _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedCode = "";
  String searchQuery = "";

  final TextEditingController searchController =
  TextEditingController();

  final List<Map<String, String>> languages = [
    {'code': 'as', 'name': 'অসমীয়া'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'brx', 'name': 'बड़ो'},
    {'code': 'doi', 'name': 'डोगरी'},
    {'code': 'en', 'name': 'English'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ'},
    {'code': 'ks', 'name': 'کٲشُر'},
    {'code': 'kok', 'name': 'कोंकणी'},
    {'code': 'mai', 'name': 'मैथिली'},
    {'code': 'ml', 'name': 'മലയാളം'},
    {'code': 'mni', 'name': 'মৈতৈলোন্'},
    {'code': 'mr', 'name': 'मराठी'},
    {'code': 'ne', 'name': 'नेपाली'},
    {'code': 'or', 'name': 'ଓଡ଼ିଆ'},
    {'code': 'pa', 'name': 'ਪੰਜਾਬੀ'},
    {'code': 'sa', 'name': 'संस्कृत'},
    {'code': 'sat', 'name': 'ᱥᱟᱱᱛᱟᱲᱤ'},
    {'code': 'sd', 'name': 'سنڌي'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'te', 'name': 'తెలుగు'},
    {'code': 'ur', 'name': 'اردو'},
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  Future<void> selectLanguage(
      BuildContext context, String code) async {
    final langProvider =
    Provider.of<LanguageProvider>(context, listen: false);

    await langProvider.loadLanguage(code);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GuestDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final crossAxisCount = screenWidth < 600
        ? 3
        : screenWidth < 1000
        ? 4
        : 5;

    /// Filter languages
    final filteredLanguages = languages.where((lang) {
      return lang['name']!
          .toLowerCase()
          .contains(searchQuery);
    }).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                /// TITLE
                const Text(
                  'Select Your Language',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                /// GRID
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredLanguages.length,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3.5,
                    ),
                    itemBuilder: (context, index) {
                      final lang = filteredLanguages[index];

                      final isSelected =
                          selectedCode == lang['code'];

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            selectedCode = lang['code']!;
                          });
                          selectLanguage(
                              context, lang['code']!);
                        },
                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            borderRadius:
                            BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                              color: Colors.yellow,
                              width: 2,
                            )
                                : null,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            lang['name']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : const Color(0xFF1E3C72),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
