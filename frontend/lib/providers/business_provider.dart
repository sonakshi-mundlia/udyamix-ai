import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class Business {
  final String id;
  final String name;

  Business({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Business.fromJson(Map<String, dynamic> json) =>
      Business(id: json['id'], name: json['name']);
}

class BusinessProvider extends ChangeNotifier {
  String? _selectedBusinessId;
  String? _businessName;
  List<Business> _businesses = [];

  String? get businessId => _selectedBusinessId;
  String? get businessName => _businessName;
  List<Business> get businesses => _businesses;

  /// Set businesses manually
  void setBusinesses(List<Business> list, {String? selectedId}) {
    _businesses = list;

    if (selectedId != null && _businesses.any((b) => b.id == selectedId)) {
      final selected = _businesses.firstWhere((b) => b.id == selectedId);
      _selectedBusinessId = selected.id;
      _businessName = selected.name;
      _saveSelectedBusinessToPrefs();
    } else if (_businesses.length == 1 && _selectedBusinessId == null) {
      final first = _businesses.first;
      setBusiness(first.id, first.name);
    }

    notifyListeners();
  }

  /// Select a single business
  Future<void> setBusiness(String businessId, String businessName) async {
    _selectedBusinessId = businessId;
    _businessName = businessName;

    if (!_businesses.any((b) => b.id == businessId)) {
      _businesses.add(Business(id: businessId, name: businessName));
    }

    await _saveSelectedBusinessToPrefs();
    notifyListeners();
  }

  /// Load businesses: Prefs first, then login API if empty
  Future<void> loadBusinesses({required String mobile, String? email}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1️⃣ Load from SharedPreferences
    final storedList = prefs.getStringList('businesses');
    if (storedList != null && storedList.isNotEmpty) {
      _businesses = storedList
          .map((b) => Business.fromJson(jsonDecode(b)))
          .toList();

      final storedId = prefs.getString('selected_business_id');
      if (storedId != null && _businesses.any((b) => b.id == storedId)) {
        _selectedBusinessId = storedId;
        _businessName =
            _businesses.firstWhere((b) => b.id == storedId).name;
      } else if (_businesses.length == 1) {
        final first = _businesses.first;
        await setBusiness(first.id, first.name);
      }

      notifyListeners();
      return; // ✅ Already loaded from prefs
    }

    // 2️⃣ Fetch from login API if prefs empty
    try {
      final fetchedBusinesses =
      await ApiService.getLoginBusinesses(mobile: mobile, email: email);
      // Convert response to List<Business>
      final list = fetchedBusinesses.entries
          .map((entry) => Business(
          id: entry.value['id'],
          name: entry.value['name']))
          .toList();

      if (list.isNotEmpty) {
        setBusinesses(list);
        await setBusiness(list.first.id, list.first.name);
      }
    } catch (e) {
      print("❌ Failed to fetch businesses: $e");
    }

    notifyListeners();
  }

  /// Clear all business data
  Future<void> clearBusiness() async {
    _selectedBusinessId = null;
    _businessName = null;
    _businesses = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_business_id');
    await prefs.remove('business_name');
    await prefs.remove('businesses');
    notifyListeners();
  }

  /// Save businesses & selected to SharedPreferences
  Future<void> _saveSelectedBusinessToPrefs() async {
    if (_selectedBusinessId != null && _businessName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_business_id', _selectedBusinessId!);
      await prefs.setString('business_name', _businessName!);
      await prefs.setStringList(
        'businesses',
        _businesses.map((b) => jsonEncode(b.toJson())).toList(),
      );
    }
  }
}