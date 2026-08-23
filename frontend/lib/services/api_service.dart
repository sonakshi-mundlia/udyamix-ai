import 'dart:io';

import 'package:dio/dio.dart';

import '../models/dashboard_model.dart';
import '../models/dashboard_background_model.dart';
import '../models/ai_insight_model.dart';
import '../models/expense_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../models/ocr_result_model.dart';
import '../models/inventory_model.dart';
import '../services/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ======================
  // AUTH
  // ======================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    String? email,
    required String password,
    required String businessName,
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'mobile': mobile,
          'email': email,
          'password': password,
          'business_name': businessName,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Registration failed',
      );
    }
  }

  // ======================
  // LOGIN – STEP 1
  // ======================

  static Future<Map<String, dynamic>> getLoginBusinesses({
    required String mobile,
    String? email,
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/auth/login/businesses',
        data: {
          'mobile': mobile,
          if (email != null) 'email': email,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to get businesses',
      );
    }
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
    try {
      final response = await DioClient.dio.post(
        '/auth/login',
        data: {
          'mobile': mobile,
          if (email != null) 'email': email,
          'password': password,
          'business_id': businessId,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Login failed',
      );
    }
  }

  static Future<UserModel> fetchProfile() async {
    try {
      final response = await DioClient.dio.get(
        '/auth/profile',
      );

      return UserModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch profile',
      );
    }
  }

  static Future<bool> isLoggedIn() async {
    // Keep this local check.
    // It does not need an API request.
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');

    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> updateUserInfo({
    String? name,
    String? email,
    String? mobile,
  }) async {
    try {
      final response = await DioClient.dio.put(
        '/auth/update-info',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (mobile != null) 'mobile': mobile,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to update user information',
      );
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await DioClient.dio.patch(
        '/auth/update-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to change password',
      );
    }
  }

  // ======================
  // BUSINESS
  // ======================

  static Future<Map<String, dynamic>> updateBusinessName({
    required String name,
  }) async {
    try {
      final response = await DioClient.dio.put(
        '/business/update-name',
        data: {
          'name': name,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to update business',
      );
    }
  }

  static Future<Map<String, dynamic>> deleteBusiness() async {
    try {
      final response = await DioClient.dio.delete(
        '/business/delete',
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to delete business',
      );
    }
  }

  // ======================
  // DASHBOARD
  // ======================

  static Future<DashboardBackgroundModel> getDashboardBackground(
      String lang,
      ) async {
    try {
      final response = await DioClient.dio.get(
        '/dashboard/background',
        options: Options(
          headers: {
            'Accept-Language': lang,
          },
        ),
      );

      return DashboardBackgroundModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } catch (e) {

      return DashboardBackgroundModel(
        businessName: '',
        data: [],
        aiError: true,
      );
    }
  }

  static Future<FullDashboardModel> getDashboard({
    DateTime? date,
  }) async {
    try {
      final response = await DioClient.dio.get(
        '/dashboard/metrics',
        queryParameters: {
          if (date != null)
            'date': date.toIso8601String().split('T').first,
        },
      );

      final decoded = response.data;

      final data = decoded['data'] ?? decoded;

      return FullDashboardModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Dashboard error',
      );
    }
  }

  // ======================
  // AI INSIGHTS
  // ======================

  static Future<List<AIInsightModel>> fetchInsights({
    String? window,
    String lang = 'en',
  }) async {
    try {
      final response = await DioClient.dio.get(
        '/ai-insights/',
        queryParameters: {
          'window': window ?? '7' ,
        },
        options: Options(
          headers: {
            'Accept-Language': lang,
          },
        ),
      );

      if (response.data is! List) {
        throw Exception('Invalid insights response');
      }

      return (response.data as List)
          .map(
            (e) => AIInsightModel.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Insight fetch error',
      );
    } catch (e) {
      rethrow;
    }
  }

  // ======================
  // SALES
  // ======================

  static Future<Sale> addSale(SaleCreate request) async {
    try {
      final response = await DioClient.dio.post(
        '/sales/',
        data: request.toJson(),
      );

      return Sale.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to add sale',
      );
    }
  }

  static Future<List<Sale>> getPaidSales() async {
    try {
      final response = await DioClient.dio.get(
        '/sales/paid',
      );

      return (response.data as List)
          .map(
            (e) => Sale.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch sales',
      );
    }
  }

  static Future<List<Sale>> getUnpaidSales() async {
    try {
      final response = await DioClient.dio.get(
        '/sales/unpaid',
      );

      return (response.data as List)
          .map(
            (e) => Sale.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch sales',
      );
    }
  }

  static Future<List<Sale>> listSales() async {
    try {
      final response = await DioClient.dio.get(
        '/sales/record',
      );

      return (response.data as List)
          .map(
            (e) => Sale.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch sales',
      );
    }
  }

  // ======================
  // EXPENSES
  // ======================

  static Future<Expense> addExpense(
      ExpenseCreate request,
      ) async {
    try {
      final response = await DioClient.dio.post(
        '/expenses/',
        data: request.toJson(),
      );

      return Expense.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to add expense',
      );
    }
  }

  static Future<List<Expense>> getPaidExpenses() async {
    try {
      final response = await DioClient.dio.get(
        '/expenses/paid',
      );

      return (response.data as List)
          .map(
            (e) => Expense.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch expenses',
      );
    }
  }

  static Future<List<Expense>> getUnpaidExpenses() async {
    try {
      final response = await DioClient.dio.get(
        '/expenses/unpaid',
      );

      return (response.data as List)
          .map(
            (e) => Expense.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch expenses',
      );
    }
  }

  static Future<List<Expense>> listExpenses() async {
    try {
      final response = await DioClient.dio.get(
        '/expenses/record',
      );

      return (response.data as List)
          .map(
            (e) => Expense.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch expenses',
      );
    }
  }

  // ======================
  // OCR
  // ======================

  static Future<OCRResultModel> uploadDocumentOCR({
    required File file,
    String lang = 'en',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await DioClient.dio.post(
        '/ocr/upload',
        data: formData,
        options: Options(
          headers: {
            'Accept-Language': lang,
          },
        ),
      );

      return OCRResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'OCR upload failed',
      );
    }
  }

  // ======================
  // INVENTORY
  // ======================

  static Future<InventoryItem> addInventory(
      String productName,
      String brand,
      double? quantity,
      String unit,
      int stockQuantity, {
        double? pricePerUnit,
      }) async {
    try {
      final response = await DioClient.dio.post(
        '/inventory/',
        data: {
          'product_name': productName,
          'brand': brand,
          'quantity': quantity,
          'unit': unit,
          'stock_quantity': stockQuantity,
          'price_per_unit': pricePerUnit ?? 0.0,
        },
      );

      return InventoryItem.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to add inventory',
      );
    }
  }

  static Future<List<InventoryItem>> fetchInventoryList() async {
    try {
      final response = await DioClient.dio.get(
        '/inventory/list',
      );

      return (response.data as List)
          .map(
            (e) => InventoryItem.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to fetch inventory',
      );
    }
  }

  static Future<InventoryItem> updateInventory(
      String inventoryId,
      String productName,
      String brand,
      double? quantity,
      String unit,
      int stockQuantity, {
        double? pricePerUnit,
      }) async {
    try {
      final response = await DioClient.dio.put(
        '/inventory/$inventoryId',
        data: {
          'product_name': productName,
          'brand': brand,
          'quantity': quantity,
          'unit': unit,
          'stock_quantity': stockQuantity,
          'price_per_unit': pricePerUnit ?? 0.0,
        },
      );

      return InventoryItem.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to update inventory',
      );
    }
  }

  static Future<void> deleteInventory(
      String inventoryId,
      ) async {
    try {
      await DioClient.dio.delete(
        '/inventory/$inventoryId',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Failed to delete inventory item',
      );
    }
  }

  // ======================
  // CHAT
  // ======================

  static Future<Map<String, dynamic>?> sendGuestChat({
    required String message,
    String lang = 'en',
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/chat/guest',
        data: {
          'query': message,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept-Language': lang,
          },
        ),
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return null;
    } on DioException catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sendBusinessChat({
    required String message,
    required String lang,
  }) async {
    try {
      final response = await DioClient.dio.post(
        '/chat/business',
        data: {
          'query': message,
          'lang': lang,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept-Language': lang,
          },
        ),
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Business chat failed',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      final response = await DioClient.dio.get(
        '/chat/get-history',
      );

      final data = Map<String, dynamic>.from(response.data);

      return List<Map<String, dynamic>>.from(
        data['history'] ?? [],
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Fetch chat history failed',
      );
    }
  }

  static Future<bool> deleteChatHistory() async {
    try {
      await DioClient.dio.delete(
        '/chat/delete-history',
      );

      return true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ??
            e.message ??
            'Delete chat history failed',
      );
    }
  }
}