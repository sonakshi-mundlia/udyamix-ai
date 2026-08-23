import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/business_provider.dart';
import '../models/user_model.dart';
import '../services/local_user_service.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailOrMobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  bool _businessLoading = false;

  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;

  Timer? _debounce;
  String _lastFetchedInput = '';

  @override
  void initState() {
    super.initState();
    _emailOrMobileController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailOrMobileController.dispose();
    _passwordController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final input = _emailOrMobileController.text.trim();

    if (input != _lastFetchedInput) {
      _businesses.clear();
      _selectedBusiness = null;
      _businessController.clear();
      setState(() {});
    }

    final isEmail =
    RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input);
    final isMobile = RegExp(r'^[0-9]{10}$').hasMatch(input);

    if (!(isEmail || isMobile)) return;
    if (input == _lastFetchedInput) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _lastFetchedInput = input;
      _fetchBusinesses();
    });
  }

  Future<void> _fetchBusinesses() async {
    final input = _emailOrMobileController.text.trim();
    if (input.isEmpty) return;

    setState(() => _businessLoading = true);

    try {
      final result = await ApiService.getLoginBusinesses(
        email: input.contains('@') ? input : null,
        mobile: input.contains('@') ? '' : input,
      );

      _businesses =
      List<Map<String, dynamic>>.from(result['businesses'] ?? []);

      if (_businesses.length == 1) {
        _selectedBusiness = _businesses.first;
        _businessController.text =
        _selectedBusiness!['business_name'];
      } else {
        _selectedBusiness = null;
        _businessController.clear();
      }
    } catch (_) {
      _businesses.clear();
    } finally {
      setState(() => _businessLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select business")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final input = _emailOrMobileController.text.trim();

      // 🔹 Call Login API
      final result = await ApiService.login(
        email: input.contains('@') ? input : null,
        mobile: input.contains('@') ? '' : input,
        password: _passwordController.text.trim(),
        businessId: _selectedBusiness!['business_id'],
      );


      final prefs = await SharedPreferences.getInstance();

      // 🔹 Save token & login flag
      await prefs.setString('access_token', result['access_token']);
      await prefs.setBool('is_logged_in', true);

      // 🔹 Create UserModel
      final userModel = UserModel(
        name: result['name'] ?? '',
        email: result['email'],
        mobile: result['mobile'] ?? '',
      );

      // 🔹 Save user locally
      await LocalUserService.saveUser(userModel);
      context.read<UserProvider>().setUser(userModel);

      // 🔹 Update BusinessProvider
      final businessProvider = context.read<BusinessProvider>();
      final newBusinessId = _selectedBusiness!['business_id'];
      final newBusinessName = _selectedBusiness!['business_name'];

      // Copy current businesses
      final currentList = List<Business>.from(businessProvider.businesses);

      // Add new business if it doesn't exist
      if (!currentList.any((b) => b.id == newBusinessId)) {
        currentList.add(Business(id: newBusinessId, name: newBusinessName));
      }

      // Set updated list & select the logged-in business
      businessProvider.setBusinesses(
        currentList,
        selectedId: newBusinessId,
      );

      if (!mounted) return;

      // 🔹 Navigate to Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid credentials"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.of(context).size;

    final horizontalPadding = size.width < 400 ? 12.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.translate('login')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          lang.translate('welcome_back'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _field(
                          controller: _emailOrMobileController,
                          label: lang.translate('email_or_mobile'),
                          icon: Icons.person,
                        ),

                        _field(
                          controller: _passwordController,
                          label: lang.translate('password'),
                          icon: Icons.lock,
                          obscure: !_showPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.blue,
                            ),
                            onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (_businessLoading)
                          const LinearProgressIndicator(
                            color: Colors.blue,
                          )
                        else if (_businesses.isNotEmpty)
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedBusiness,
                            items: _businesses
                                .map((b) => DropdownMenuItem(
                              value: b,
                              child:
                              Text(b['business_name']),
                            ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedBusiness = v;
                                _businessController.text =
                                    v?['business_name'] ?? '';
                              });
                            },
                            decoration: InputDecoration(
                              labelText: lang.translate('select_business'),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else
                          _field(
                            controller: _businessController,
                            label: lang.translate('business'),
                            icon: Icons.business,
                            readOnly: true,
                          ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                            _loading ? null : _handleLogin,
                            child: _loading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(lang.translate('login')),
                          ),
                        ),

                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                              lang.translate('new_user_register')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FIELD HELPER
Widget _field({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscure = false,
  bool readOnly = false,
  Widget? suffixIcon,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide:
          const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (v) =>
      v == null || v.isEmpty ? "Required" : null,
    ),
  );
}
