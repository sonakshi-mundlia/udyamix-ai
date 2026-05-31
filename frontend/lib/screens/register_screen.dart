import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_user_service.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';
import '../providers/business_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = context.read<LanguageProvider>();
    setState(() => _loading = true);

    try {
      final result = await ApiService.register(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        password: _passwordController.text.trim(),
        businessName: _businessController.text.trim(),
      );

      if (result.containsKey('access_token')) {
        final prefs = await SharedPreferences.getInstance();

        // 🔹 Save token & login flag
        await prefs.setString('access_token', result['access_token']);
        await prefs.setBool('is_logged_in', true);

        // 🔹 Create user model
        final user = UserModel(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );

        // 🔹 Save user locally
        await LocalUserService.saveUser(user);
        context.read<UserProvider>().setUser(user);

        // 🔹 Update BusinessProvider: add business to list & select it
        final businessProvider = context.read<BusinessProvider>();
        businessProvider.setBusinesses(
          [
            Business(
              id: result['business_id'],
              name: _businessController.text.trim(),
            ),
          ],
          selectedId: result['business_id'],
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('registration_success')),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        // 🔹 Navigate to Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false,
        );
      } else {
        throw Exception('Registration failed');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('registration_failed')),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(lang.translate('register')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth > 600 ? 450 : double.infinity,
            ),
            child: Card(
              elevation: 6,
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
                        lang.translate('create_account'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field(
                        controller: _nameController,
                        label: lang.translate('name'),
                        icon: Icons.person,
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                      ),
                      _field(
                        controller: _mobileController,
                        label: lang.translate('mobile'),
                        icon: Icons.phone,
                        keyboard: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                            return 'Enter valid 10-digit mobile';
                          }
                          return null;
                        },
                      ),
                      _field(
                        controller: _emailController,
                        label: lang.translate('email'),
                        icon: Icons.email,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v)) {
                              return 'Enter valid email';
                            }
                          }
                          return null;
                        },
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      _field(
                        controller: _businessController,
                        label: lang.translate('business_name'),
                        icon: Icons.business,
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 25),
                      _loading
                          ? const CircularProgressIndicator(
                        color: Colors.blue,
                      )
                          : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: register,
                          child: Text(lang.translate('register')),
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
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(lang.translate('already_registered')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =======================
  // FIELD WIDGET
  // =======================
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
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
      ),
    );
  }
}
