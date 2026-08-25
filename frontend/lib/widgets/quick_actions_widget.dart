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
import '../models/ocr_result_model.dart';

class QuickActionsWidget extends StatefulWidget {
  const QuickActionsWidget({super.key});

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> {
  File? photoFile;
  File? documentFile;

  bool isLoading = false;

  OCRResultModel? ocrResult;

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> capturePhoto() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) return;

      final file = File(image.path);

      setState(() {
        photoFile = file;
      });

      // Close upload dialog first
      if (mounted) {
        Navigator.of(context).pop();
      }

      await processOCR(file);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
        ),
      );
    }
  }

  // ============================================================
  // FILE PICKER
  // ============================================================

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (result == null) return;

      final path = result.files.single.path;

      if (path == null) return;

      final file = File(path);

      setState(() {
        documentFile = file;
      });

      // Close upload dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      await processOCR(file);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
        ),
      );
    }
  }

  // ============================================================
  // OCR PROCESS
  // ============================================================

  Future<void> processOCR(File file) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      ocrResult = null;
    });

    try {
      final result = await ApiService.uploadDocumentOCR(
        file: file,
      );

      if (!mounted) return;

      setState(() {
        ocrResult = result;
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document processed successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OCR processing failed: $e'),
        ),
      );
    }
  }

  // ============================================================
  // PHOTO DIALOG
  // ============================================================

  void openPhotoContainer() {
    final t = context.watch<LanguageProvider>().translate;
    _openDialog(
      icon: Icons.camera_alt,
      title: t('quick_actions.capture_photo'),
      onPressed: capturePhoto,
      file: photoFile,
      isImage: true,
    );
  }

  // ============================================================
  // FILE DIALOG
  // ============================================================

  void openFileContainer() {
    final t = context.watch<LanguageProvider>().translate;
    _openDialog(
      icon: Icons.upload_file,
      title: t('quick_actions.select_file'),
      onPressed: pickFile,
      file: documentFile,
      isImage: false,
    );
  }

  // ============================================================
  // UPLOAD DIALOG
  // ============================================================

  void _openDialog({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    File? file,
    required bool isImage,
  }) {
    final t = context.watch<LanguageProvider>().translate;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 200 : 400,
            vertical: 50,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                // ------------------------------------------------
                // ICON / FILE PREVIEW
                // ------------------------------------------------

                if (file != null)
                  isImage
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        size: 60,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        file.path.split(Platform.pathSeparator).last,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Icon(
                    icon,
                    size: 60,
                    color: Colors.blue,
                  ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // BLUE BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,

                      elevation: 2,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    icon: Icon(
                      icon,
                      color: Colors.white,
                    ),

                    label: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ------------------------------------------------
                // CLOSE
                // ------------------------------------------------

                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },

                  child: Text(
                    t('quick_actions.close'),
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // OCR RESULT CONTAINER
  // ============================================================

  Widget _buildOCRResult() {
    if (ocrResult == null) {
      return const SizedBox.shrink();
    }

    final result = ocrResult!;

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Row(
            children: [

              const Icon(
                Icons.document_scanner,
                color: Colors.blue,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'OCR Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    ocrResult = null;
                  });
                },

                icon: const Icon(
                  Icons.close,
                ),
              ),
            ],
          ),

          const Divider(),

          const SizedBox(height: 10),

          _resultRow(
            'Type',
             result.detectedType ?? 'Unknown'
          ),

          _resultRow(
            'Amount',
            '₹${result.detectedAmount.toStringAsFixed(2)}',
          ),

          _resultRow(
            'Party',
            result.detectedParty ?? 'Not detected',
          ),

          _resultRow(
            'Category',
            result.detectedCategory ?? 'Not detected',
          ),

          _resultRow(
            'Date',
            result.detectedDate?.toString() ?? 'Unknown',
          ),

          _resultRow(
            'Confidence',
            '${(result.confidence * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 100,

            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING SCANNER
  // ============================================================

  Widget _buildLoadingScanner() {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.all(16),

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: const Column(
        children: [

          SizedBox(
            width: 45,
            height: 45,

            child: CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),

          SizedBox(height: 18),

          Text(
            'Scanning document...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Extracting and processing your data',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width < 600 ? 2 : 4;

    final padding = width < 600 ? 16.0 : 24.0;

    final containerHeight = width < 600 ? 50.0 : 90.0;

    final containerWidth = width < 600 ? 100.0 : 140.0;

    final t = context.watch<LanguageProvider>().translate;

    final actions = [
      {
        "icon": Icons.camera_alt,
        "label": t('quick_actions.upload_photo'),
        "action": openPhotoContainer,
      },

      {
        "icon": Icons.upload_file,
        "label": t('quick_actions.upload_file'),
        "action": openFileContainer,
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
        },
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
        },
      },
    ];

    return Column(
      children: [

        // ======================================================
        // LOADING
        // ======================================================

        _buildLoadingScanner(),

        // ======================================================
        // OCR RESULT
        // ======================================================

        _buildOCRResult(),

        // ======================================================
        // QUICK ACTIONS
        // ======================================================

        Padding(
          padding: EdgeInsets.all(padding),

          child: GridView.builder(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            itemCount: actions.length,

            gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,

              crossAxisSpacing: padding,

              mainAxisSpacing: padding,

              childAspectRatio:
              containerWidth / containerHeight,
            ),

            itemBuilder: (context, index) {
              final action = actions[index];

              return InkWell(
                onTap: isLoading
                    ? null
                    : action["action"] as VoidCallback,

                borderRadius: BorderRadius.circular(12),

                child: Container(
                  height: containerHeight,

                  width: containerWidth,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(12),

                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,

                        color:
                        Colors.black.withOpacity(0.08),

                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [

                      Icon(
                        action["icon"] as IconData,

                        size:
                        width < 600 ? 26 : 32,

                        color: Colors.blue,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        action["label"] as String,

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,

                          fontSize:
                          width < 600 ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

