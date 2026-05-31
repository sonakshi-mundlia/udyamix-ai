import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_user_service.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Set user and notify listeners
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Load user from local storage
  Future<void> loadFromLocal() async {
    _user = await LocalUserService.getUser();
    notifyListeners();
  }

  /// Clear user data
  void clearUser() {
    _user = null;
    notifyListeners();
  }

  /// Refresh profile from API
  Future<void> refreshProfile() async {
    try {
      final data = await ApiService.fetchProfile();
      if (data != null) {
        _user = UserModel(
          name: data.name ?? '',
          email: data.email,
          mobile: data.mobile ?? '',
        );
        await LocalUserService.saveUser(_user!); // Update local storage
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }
}