import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/api_service.dart';
import '../screens/add_sale_screen.dart';
import '../screens/add_expense_screen.dart';

class QuickActionsWidget extends StatefulWidget {
  const QuickActionsWidget({super.key});

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> {
  File? photoFile;
  File? documentFile;

  bool isLoading = false;

  Future<void> capturePhoto() async {
    final t = context.read<LanguageProvider>().translate;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) return;

      setState(() {
        photoFile = File(image.path);
        isLoading = true;
      });

      await ApiService.uploadDocumentOCR(file: photoFile!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('quick_actions.photo_uploaded'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('quick_actions.upload_failed'))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickFile() async {
    final t = context.read<LanguageProvider>().translate;

    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null) return;

      setState(() {
        documentFile = File(result.files.single.path!);
        isLoading = true;
      });

      await ApiService.uploadDocumentOCR(file: documentFile!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('quick_actions.file_uploaded'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('quick_actions.upload_failed'))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void openPhotoContainer() => _openDialog(
    icon: Icons.camera_alt,
    titleKey: "quick_actions.capture_photo",
    onPressed: capturePhoto,
    file: photoFile,
    isImage: true,
  );

  void openFileContainer() => _openDialog(
    icon: Icons.upload_file,
    titleKey: "quick_actions.select_file",
    onPressed: pickFile,
    file: documentFile,
    isImage: false,
  );

  void _openDialog({
    required IconData icon,
    required String titleKey,
    required VoidCallback onPressed,
    File? file,
    required bool isImage,
  }) {
    final t = context.read<LanguageProvider>().translate;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (file != null)
                isImage
                    ? Image.file(file, height: 120)
                    : Column(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 60),
                    const SizedBox(height: 8),
                    Text(file.path.split('/').last),
                  ],
                )
              else
                Icon(icon, size: 60, color: Colors.blue),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: isLoading ? null : onPressed,
                icon: Icon(icon),
                label: Text(t(titleKey)),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('quick_actions.close')),
              ),

              if (isLoading) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().translate;
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width < 600 ? 2 : 4;
    final padding = width < 600 ? 16.0 : 24.0;
    final containerHeight = width < 600 ? 50.0 : 90.0;
    final containerWidth = width < 600 ? 100.0 : 140.0;

    final actions = [
      {
        "icon": Icons.camera_alt,
        "label": t('quick_actions.upload_photo'),
        "action": openPhotoContainer
      },
      {
        "icon": Icons.upload_file,
        "label": t('quick_actions.upload_file'),
        "action": openFileContainer
      },
      {
        "icon": Icons.shopping_cart,
        "label": t('quick_actions.add_sale'),
        "action": () async {

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddSaleScreen(),
            ),
          );

          if (context.mounted) {
            context.read<DashboardProvider>().refresh();
          }
        }
      },
      {
        "icon": Icons.money,
        "label": t('quick_actions.add_expense'),
        "action": () async {

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );

          if (context.mounted) {
            context.read<DashboardProvider>().refresh();
          }
        }
      },
    ];

    return Padding(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: padding,
          mainAxisSpacing: padding,
          childAspectRatio: containerWidth / containerHeight,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];

          return InkWell(
            onTap: action["action"] as VoidCallback,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: containerHeight,
              width: containerWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action["icon"] as IconData,
                      size: width < 600 ? 26 : 32,
                      color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    action["label"] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width < 600 ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
