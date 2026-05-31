import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/business_provider.dart';
import '../providers/language_provider.dart';
import '../services/local_user_service.dart';
import '../widgets/privacy_widget.dart';
import 'settings_screen.dart';
import 'guest_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool showPrivacyOverlay = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  /// Initialize user & business info
  Future<void> _initializeProfile() async {
    final userProvider = context.read<UserProvider>();
    final businessProvider = context.read<BusinessProvider>();

    print("🔹 Initializing Profile...");

    // Load user from local storage
    await userProvider.loadFromLocal();

    if (userProvider.isLoggedIn) {
      if (userProvider.user != null) {
        await userProvider.refreshProfile();
      }
    } else {
      print("User is not logged in.");
    }
    final email = userProvider.user!.email ?? "";
    final mobile = userProvider.user!.mobile;

    // Load selected business
    await businessProvider.loadBusinesses(email: email, mobile: mobile);
    print("Businesses loaded: ${businessProvider.businesses.map((b) => b.name).toList()}");
    print("Selected business ID: ${businessProvider.businessId}");
    print("Selected business name: ${businessProvider.businessName}");

    // If only 1 business, set it as default
    if (businessProvider.businesses.length == 1 &&
        businessProvider.businessId == null) {
      final first = businessProvider.businesses.first;
      await businessProvider.setBusiness(first.id, first.name);
    }

    if (!mounted) return;
    if (userProvider.user != null) {
      setState(() => isLoading = false);
    }
  }

  /// Logout user
  Future<void> _logout(BuildContext context) async {
    await LocalUserService.clear();
    context.read<UserProvider>().clearUser();
    await context.read<BusinessProvider>().clearBusiness();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GuestDashboardScreen()),
          (_) => false,
    );
  }

  Widget _infoRow(IconData icon, String value,
      {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: fontSize + 6),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color color = Colors.black,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final businessProvider = context.watch<BusinessProvider>();
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final headerHeight = isMobile ? 200.0 : 300.0;
    final avatarRadius = isMobile ? 40.0 : 55.0;
    final infoFontSize = isMobile ? 14.0 : 16.0;

    final user = userProvider.user;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(t('profile.no_user'))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: headerHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/images/profile.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35), BlendMode.darken),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -avatarRadius / 1.2,
                    left: 20,
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: avatarRadius - 4,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          size: avatarRadius,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withOpacity(0.7),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            size: 18, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: avatarRadius + 20),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                Icons.person,
                                (user.name.isNotEmpty) ? user.name : "Guest User",
                                isBold: true,
                                fontSize: isMobile ? 20 : 24,
                              ),
                              if ((user.email ?? '').isNotEmpty)
                                _infoRow(Icons.email, user.email ?? '',
                                    fontSize: infoFontSize),
                              if (user.mobile.isNotEmpty)
                                _infoRow(Icons.phone, user.mobile,
                                    fontSize: infoFontSize),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Business Section
                      if (businessProvider.businesses.isNotEmpty)
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.business, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: businessProvider.businesses.length > 1
                                      ? DropdownButton<String>(
                                    isExpanded: true,
                                    value: businessProvider.businessId,
                                    items: businessProvider.businesses
                                        .map((b) => DropdownMenuItem(
                                      value: b.id,
                                      child: Text(b.name),
                                    ))
                                        .toList(),
                                    onChanged: (value) async {
                                      if (value != null) {
                                        final selected = businessProvider
                                            .businesses
                                            .firstWhere(
                                                (b) => b.id == value);
                                        await businessProvider.setBusiness(
                                            selected.id, selected.name);
                                        setState(() {});
                                      }
                                    },
                                  )
                                      : Text(
                                    businessProvider.businessName ??
                                        businessProvider
                                            .businesses.first.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 25),

                      // Settings & Actions
                      Text(
                        t('profile.settings'),
                        style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _actionItem(
                        icon: Icons.settings,
                        title: t('profile.app_settings'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),
                      _actionItem(
                        icon: Icons.privacy_tip,
                        title: t('profile.privacy_security'),
                        onTap: () => setState(() => showPrivacyOverlay = true),
                      ),
                      _actionItem(
                        icon: Icons.language,
                        title: t('profile.language'),
                        trailing: DropdownButton<String>(
                          value: langProvider.currentLanguage.isNotEmpty
                              ? langProvider.currentLanguage
                              : langProvider.supportedLanguages.first,
                          items: langProvider.supportedLanguages
                              .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang.toUpperCase()),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) langProvider.loadLanguage(value);
                          },
                        ),
                        onTap: null,
                      ),
                      _actionItem(
                        icon: Icons.logout,
                        title: t('profile.logout'),
                        color: Colors.red,
                        onTap: () => _logout(context),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Privacy Overlay
          if (showPrivacyOverlay)
            GestureDetector(
              onTap: () => setState(() => showPrivacyOverlay = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // ✅ Prevent closing when clicking inside
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
                      padding: const EdgeInsets.all(20),
                      constraints: BoxConstraints(
                        maxWidth: 500,
                        maxHeight: isMobile ? 500 : 600,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          /// 🔝 HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 40),
                              Text(
                                t('profile.privacy_security'),
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => showPrivacyOverlay = false),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// 🔽 SCROLLABLE CONTENT
                          Expanded(
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: const SingleChildScrollView(
                                child: PrivacyWidget(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// 🔘 ACTION BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => showPrivacyOverlay = false),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(t('profile.close')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
