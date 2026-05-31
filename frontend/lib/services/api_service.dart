import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_model.dart';
import '../models/dashboard_background_model.dart';
import '../models/ai_insight_model.dart';
import '../models/expense_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../models/ocr_result_model.dart';
import '../models/inventory_model.dart';
import '../providers/business_provider.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  // ======================
  // AUTH + BUSINESS HEADERS
  // ======================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');
    final businessId = prefs.getString('selected_business_id');

    print('🔐 TOKEN: $token');
    print('🏢 BUSINESS ID: $businessId');

    if (token == null) {
      throw Exception("No access token found");
    }

    if (businessId == null) {
      throw Exception("No business selected");
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Business-Id': businessId,
    };
  }

  // ======================
  // REGISTER
  // ======================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    String? email,
    required String password,
    required String businessName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'mobile': mobile,
        'email': email,
        'password': password,
        'business_name': businessName,
      }),
    );

    print('📝 REGISTER STATUS: ${response.statusCode}');
    print('📝 REGISTER BODY: ${response.body}');

    return jsonDecode(response.body);
  }

  // ======================
  // LOGIN – STEP 1
  // ======================
  static Future<Map<String, dynamic>> getLoginBusinesses({
    required String mobile,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login/businesses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        if (email != null) 'email': email,
      }),
    );

    print('🔎 LOGIN BUSINESSES STATUS: ${response.statusCode}');
    print('🔎 LOGIN BUSINESSES BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  // ======================
  // LOGIN – STEP 2
  // ======================
  static Future<Map<String, dynamic>> login({
    required String mobile,
    String? email,
    required String password,
    required String businessId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        if (email != null) 'email': email,
        'password': password,
        'business_id': businessId,
      }),
    );

    print('🔑 LOGIN STATUS: ${response.statusCode}');
    print('🔑 LOGIN BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  static Future<UserModel> fetchProfile() async {
    final url = Uri.parse('$_baseUrl/auth/profile');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to fetch profile');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> updateUserInfo({
    String? name,
    String? email,
    String? mobile,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/auth/update-info'),
      headers: await _headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (mobile != null) 'mobile': mobile,
      }),
    );

    print('👤 UPDATE USER STATUS: ${response.statusCode}');
    print('👤 UPDATE USER BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/auth/update-password'),
      headers: await _headers(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    print('🔒 CHANGE PASSWORD STATUS: ${response.statusCode}');
    print('🔒 CHANGE PASSWORD BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  // ------------------------------
  // UPDATE BUSINESS
  // ------------------------------
  static Future<Map<String, dynamic>> updateBusinessName({
    required String name,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/business/update-name'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
      }),
    );

    print('🏢 UPDATE BUSINESS STATUS: ${response.statusCode}');
    print('🏢 UPDATE BUSINESS BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  // ------------------------------
  // DELETE BUSINESS
  // ------------------------------
  static Future<Map<String, dynamic>> deleteBusiness() async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/business/delete'),
      headers: await _headers(),
    );

    print('🗑️ DELETE BUSINESS STATUS: ${response.statusCode}');
    print('🗑️ DELETE BUSINESS BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  // ======================
  // DASHBOARD
  // ======================

  static Future<DashboardBackgroundModel> getDashboardBackground(String lang) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/background'),
        headers: {
          ...(await _headers()),
          "Accept-Language": lang,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return DashboardBackgroundModel.fromJson(jsonData);
      } else {
        throw Exception("Failed to load dashboard");
      }
    } catch (e) {
      print("Dashboard API Error: $e");

      // ✅ fallback (VERY IMPORTANT)
      return DashboardBackgroundModel(
        businessName: "",
        data: [],
        aiError: true,
      );
    }
  }

  /// Get dashboard data, optionally for a specific date
  static Future<FullDashboardModel> getDashboard({DateTime? date}) async {
    // Build query parameter if date is provided
    final query = date != null ? "?date=${date.toIso8601String().split('T').first}" : "";
    final url = Uri.parse('$_baseUrl/dashboard/metrics$query');

    final response = await http.get(url, headers: await _headers());

    print('📊 DASHBOARD STATUS: ${response.statusCode}');
    print('📊 DASHBOARD BODY: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(decoded['detail'] ?? 'Dashboard error');
    }

    final data = decoded['data'] ?? decoded;

    return FullDashboardModel.fromJson(data);
  }

  // ======================
  // AI INSIGHTS
  // ======================

  static Future<List<AIInsightModel>> fetchInsights({
    int window = 7,
    String lang = 'en',
  }) async {
    try {
      final headers = {
        ...(await _headers()),
        "Accept-Language": lang,
      };

      final uri = Uri.parse('$_baseUrl/ai-insights/').replace(
        queryParameters: {"window": window.toString()},
      );

      print('🔐 HEADERS (GET): $headers');
      print('🌐 LANG: $lang, WINDOW: $window');
      print('🌐 URI: $uri');

      final response = await http.get(uri, headers: headers);
      print('💡 STATUS: ${response.statusCode}');
      print('💡 BODY: ${response.body}');

      if (response.statusCode != 200) {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['detail'] ?? 'Insight fetch error');
      }

      final decoded = jsonDecode(response.body);
      return (decoded as List)
          .map((e) => AIInsightModel.fromJson(e))
          .toList();
    } catch (e) {
      print('💡 ERROR fetching insights: $e');
      rethrow;
    }
  }

  // ======================
  // SALES
  // ======================
  static Future<Sale> addSale(SaleCreate request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sales/'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Sale.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to add sale');
  }

  static Future<List<Sale>> getPaidSales() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sales/paid'),
      headers: await ApiService._headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Sale.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  static Future<List<Sale>> getUnpaidSales() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sales/unpaid'),
      headers: await ApiService._headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Sale.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  static Future<List<Sale>> listSales() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sales/record'),
      headers: await ApiService._headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Sale.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  // ======================
  // EXPENSES
  // ======================
  static Future<Expense> addExpense(ExpenseCreate request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/expenses/'),
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to add sale');
  }

  static Future<List<Expense>> getPaidExpenses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/expenses/paid'),
      headers: await ApiService._headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Expense.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  static Future<List<Expense>> getUnpaidExpenses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/expenses/paid'),
      headers: await ApiService._headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Expense.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  static Future<List<Expense>> listExpenses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/expenses/record'),
      headers: await ApiService._headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Expense.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sales');
    }
  }

  // ======================
  // OCR
  // ======================
  static Future<OCRResultModel> uploadDocumentOCR({
    required File file,
    String lang = "en",
  }) async {
    final headers = {
      ...(await _headers()),
      "Accept-Language": lang,
    };

    headers.remove('Content-Type');

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$_baseUrl/ocr/upload"),
    );

    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await http.Response.fromStream(await request.send());

    print('📄 OCR STATUS: ${response.statusCode}');
    print('📄 OCR BODY: ${response.body}');

    return OCRResultModel.fromJson(jsonDecode(response.body));
  }

  // ======================
  // INVENTORY
  // ======================
  static Future<InventoryItem> addInventory(String productName, String brand,
  double? quantity, String unit, int stockQuantity,
      {double? pricePerUnit}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/inventory/'),
      headers: await _headers(),
      body: jsonEncode({
        'product_name': productName,
        'brand': brand,
        'quantity': quantity,
        'unit': unit,
        'stock_quantity': stockQuantity,
        'price_per_unit': pricePerUnit ?? 0.0,
      }),
    );

    print('📦 ADD INVENTORY STATUS: ${response.statusCode}');
    print('📦 ADD INVENTORY BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to add inventory");
    }
  }

  static Future<List<InventoryItem>> fetchInventoryList() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/inventory/list'),
      headers: await _headers(),
    );

    print('📦 FETCH INVENTORY STATUS: ${response.statusCode}');
    print('📦 FETCH INVENTORY BODY: ${response.body}');

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => InventoryItem.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to fetch inventory list");
    }
  }

  static Future<InventoryItem> updateInventory(String inventoryId,
      String productName,
      String brand,
      double? quantity,
      String unit,
      int stockQuantity,
      {double? pricePerUnit}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/inventory/$inventoryId'),
      headers: await _headers(),
      body: jsonEncode({
        'product_name': productName,
        'brand': brand,
        'quantity': quantity,
        'unit': unit,
        'stock_quantity': stockQuantity,
        'price_per_unit': pricePerUnit ?? 0.0,
      }),
    );

    print('📦 UPDATE INVENTORY STATUS: ${response.statusCode}');
    print('📦 UPDATE INVENTORY BODY: ${response.body}');

    if (response.statusCode == 200) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update inventory");
    }
  }

  static Future<void> deleteInventory(String inventoryId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/inventory/$inventoryId'),
      headers: await _headers(),
    );

    print('📦 DELETE INVENTORY STATUS: ${response.statusCode}');
    print('📦 DELETE INVENTORY BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception("Failed to delete inventory item");
    }
  }

  // ======================
  // CHAT
  // ======================


  static Future<Map<String, dynamic>?> sendGuestChat({required String message, String lang = "en",}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/guest'),
        headers: {
          "Accept-Language": lang,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "query": message,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }
  static Future<Map<String, dynamic>?> sendBusinessChat({
    required String message,
    required String lang,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/chat/business"),
      headers: {
        ...(await _headers()),
        "Accept-Language": lang,
      },
      body: {
        "query": message,
        "lang": lang,
      },
    );

    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    final uri = Uri.parse('$_baseUrl/chat/get-history');
    final headers = await _headers();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data["history"] ?? []);
    }

    throw Exception("Fetch chat history failed: ${response.body}");
  }

  static Future<bool> deleteChatHistory() async {
    final uri = Uri.parse('$_baseUrl/chat/delete-history');
    final headers = await _headers();

    final response = await http.delete(uri, headers: headers);

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception("Delete chat history failed: ${response.body}");

  }
}

