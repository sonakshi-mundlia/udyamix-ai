import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final businessController = TextEditingController();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool isLoading = false;

  // ------------------------------
  // API METHODS
  // ------------------------------
  Future<void> updateUser() async {
    setState(() => isLoading = true);
    final langProvider = context.read<LanguageProvider>();
    try {
      await ApiService.updateUserInfo(
        name: nameController.text,
        email: emailController.text,
        mobile: mobileController.text,
      );
      showMsg(langProvider.translate('settings.messages.user_updated'));
    } catch (e) {
      showMsg(e.toString());
    }
    setState(() => isLoading = false);
  }

  Future<void> updateBusiness() async {
    setState(() => isLoading = true);
    final langProvider = context.read<LanguageProvider>();
    try {
      await ApiService.updateBusinessName(
        name: businessController.text,
      );
      showMsg(langProvider.translate('settings.messages.business_updated'));
    } catch (e) {
      showMsg(e.toString());
    }
    setState(() => isLoading = false);
  }

  Future<void> changePassword() async {
    setState(() => isLoading = true);
    final langProvider = context.read<LanguageProvider>();
    try {
      await ApiService.changePassword(
        oldPassword: oldPasswordController.text,
        newPassword: newPasswordController.text,
      );
      showMsg(langProvider.translate('settings.messages.password_changed'));
    } catch (e) {
      showMsg(e.toString());
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteBusiness() async {
    setState(() => isLoading = true);
    final langProvider = context.read<LanguageProvider>();
    try {
      await ApiService.deleteBusiness();
      showMsg(langProvider.translate('settings.messages.business_deleted'));
    } catch (e) {
      showMsg(e.toString());
    }
    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ------------------------------
  // MODAL DIALOG
  // ------------------------------
  void openDialog(Widget content) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double width = screenWidth > 700 ? 500 : screenWidth * 0.9;
    double height = screenWidth > 700 ? 400 : screenHeight * 0.5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              content,
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // BUILD METHOD
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().translate;
    final isLarge = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: Text(t("settings.title"))),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: isLarge
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildLeft(t)),
            const SizedBox(width: 20),
            Expanded(child: buildRight(t)),
          ],
        )
            : Column(
          children: [
            buildLeft(t),
            const SizedBox(height: 20),
            buildRight(t),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // LEFT SECTION
  // ------------------------------
  Widget buildLeft(Function t) {
    return Column(
      children: [
        primaryButton(t('settings.buttons.update_profile'), () {
          openDialog(buildProfileContent(t));
        }),
        const SizedBox(height: 20),
        primaryButton(t('settings.buttons.update_business'), () {
          openDialog(buildBusinessContent(t));
        }),
      ],
    );
  }

  // ------------------------------
  // RIGHT SECTION
  // ------------------------------
  Widget buildRight(Function t) {
    return Column(
      children: [
        primaryButton(t('settings.buttons.change_password'), () {
          openDialog(buildPasswordContent(t));
        }),
        const SizedBox(height: 20),
        dangerButton(t('settings.buttons.delete_business'), deleteBusiness),
      ],
    );
  }

  // ------------------------------
  // MODAL CONTENT BUILDER
  // ------------------------------
  Widget buildProfileContent(Function t) => buildModalContent(
    fields: [
      inputField(nameController, t('settings.fields.name')),
      inputField(emailController, t('settings.fields.email')),
      inputField(mobileController, t('settings.fields.mobile')),
    ],
    buttonText: t('settings.buttons.update_profile'),
    onPressed: () async {
      await updateUser();
      Navigator.of(context).pop();
    },
  );

  Widget buildBusinessContent(Function t) => buildModalContent(
    fields: [
      inputField(businessController, t('settings.fields.business_name')),
    ],
    buttonText: t('settings.buttons.update_business'),
    onPressed: () async {
      await updateBusiness();
      Navigator.of(context).pop();
    },
  );

  Widget buildPasswordContent(Function t) => buildModalContent(
    fields: [
      inputField(oldPasswordController, t('settings.fields.old_password'),
          isPassword: true),
      inputField(newPasswordController, t('settings.fields.new_password'),
          isPassword: true),
    ],
    buttonText: t('settings.buttons.change_password'),
    onPressed: () async {
      await changePassword();
      Navigator.of(context).pop();
    },
  );

  Widget buildModalContent({
    required List<Widget> fields,
    required String buttonText,
    required VoidCallback onPressed,
  }) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...fields,
          const SizedBox(height: 20),
          primaryButton(buttonText, onPressed),
        ],
      );

  // ------------------------------
  // INPUT FIELD
  // ------------------------------
  Widget inputField(TextEditingController controller, String label,
      {bool isPassword = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      );

  // ------------------------------
  // BUTTONS
  // ------------------------------
  Widget primaryButton(String text, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    ),
  );

  Widget dangerButton(String text, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );
}