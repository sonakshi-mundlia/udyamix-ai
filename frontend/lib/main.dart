import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/user_provider.dart';
import 'providers/language_provider.dart';
import 'providers/business_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/inventory_provider.dart';

import 'screens/language_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guest_dashboard_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(

    MultiProvider(

      providers: [

        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => BusinessProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => InventoryProvider(),
        ),
      ],

      child: const AppInitializer(),
    ),
  );
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() =>
      _AppInitializerState();
}

class _AppInitializerState
    extends State<AppInitializer> {

  bool _isLoading = true;

  String? _token;

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {

    final prefs =
    await SharedPreferences.getInstance();

    final languageProvider =
    context.read<LanguageProvider>();

    await languageProvider.loadSavedLanguage();

    final userProvider =
    context.read<UserProvider>();

    await userProvider.loadFromLocal();

    _token = prefs.getString('access_token');

    if (userProvider.isLoggedIn) {

      final businessProvider =
      context.read<BusinessProvider>();

      await businessProvider.loadBusinesses(

        email:
        userProvider.user?.email ?? "",

        mobile:
        userProvider.user?.mobile ?? "",
      );
    }

    if (mounted) {

      setState(() {

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {

      return const MaterialApp(

        debugShowCheckedModeBanner: false,

        home: Scaffold(

          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'MultiLang App',

      theme: ThemeData(

        useMaterial3: true,

        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(

          seedColor: Colors.blue,

          background: Colors.white,

          surface: Colors.white,

          primary: Colors.blue,
        ),

        appBarTheme: const AppBarTheme(

          backgroundColor: Colors.blue,

          foregroundColor: Colors.white,

          elevation: 0,
        ),
      ),

      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {

    final languageProvider =
    context.read<LanguageProvider>();

    if (!languageProvider.hasLanguage) {

      return LanguageScreen();
    }

    if (_token != null &&
        _token!.isNotEmpty) {

      return const DashboardScreen();
    }

    return const GuestDashboardScreen();
  }
}