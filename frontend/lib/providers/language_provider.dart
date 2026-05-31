import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Map<String, dynamic> _localizedStrings = {};
  String _currentLanguage = '';

  // All 22 official languages of India
  final List<String> supportedLanguages = [
    'en', // English
    'hi', // Hindi
    'bn', // Bengali
    'te', // Telugu
    'mr', // Marathi
    'ta', // Tamil
    'ur', // Urdu
    'gu', // Gujarati
    'kn', // Kannada
    'ml', // Malayalam
    'or', // Odia
    'pa', // Punjabi
    'as', // Assamese
    'ma', // Maithili
    'sd', // Sindhi
    'kok', // Konkani
    'dog', // Dogri
    'sat', // Santali
    'bodo', // Bodo
    'san', // Sanskrit
    'ne', // Nepali
    'bh', // Bihari
  ];

  String get currentLanguage => _currentLanguage;
  bool get hasLanguage => _currentLanguage.isNotEmpty;

  /// 🔹 Translate a single string from nested JSON
  String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;
    for (var k in keys) {
      if (value[k] == null) return key;
      value = value[k];
    }
    return value.toString();
  }

  /// 🔹 Translate a list of strings from nested JSON
  List<dynamic> translateList(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;
    for (var k in keys) {
      if (value[k] == null) return [];
      value = value[k];
    }
    if (value is List) {
      return value;
    }
    return [];
  }

  // ------------------------------
// Safe list translator
// Returns List<dynamic> to handle both List<Map> and List<String>
// -----------------------------
  List<String> translateStringList(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;

    for (var k in keys) {
      if (value[k] == null) return [];
      value = value[k];
    }

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    return [];
  }


  Future<void> loadLanguage(String langCode) async {
    _currentLanguage = langCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);

    try {
      final jsonString = await rootBundle.loadString('lib/l10n/$langCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
    } catch (e) {
      _localizedStrings = {};
      debugPrint("Language file not found for $langCode: $e");
    }

    notifyListeners();
  }

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? '';
    if (_currentLanguage.isNotEmpty) {
      await loadLanguage(_currentLanguage);
    }
  }
}
