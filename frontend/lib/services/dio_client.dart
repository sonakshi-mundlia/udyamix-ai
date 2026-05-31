import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();

        final token = prefs.getString('access_token');
        final businessId = prefs.getString('selected_business_id');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (businessId != null) {
          options.headers['X-Business-Id'] = businessId;
        }

        return handler.next(options);
      },

      onError: (error, handler) {
        return handler.next(error);
      },
    ),
  );
}
