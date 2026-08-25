import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ocr_result_model.dart';
import '../services/api_service.dart';

class OCRProvider extends ChangeNotifier {
  bool _isUploading = false;
  OCRResultModel? _result;
  String? _error;

  bool get isUploading => _isUploading;

  OCRResultModel? get result => _result;

  String? get error => _error;

  Future<void> uploadDocument(File file) async {
    _isUploading = true;
    _result = null;
    _error = null;

    notifyListeners();

    try {
      final result = await ApiService.uploadDocumentOCR(
        file: file,
      );

      _result = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}