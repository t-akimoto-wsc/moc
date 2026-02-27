import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'si003.dart' as screen003;
import 'si004.dart' as screen004;
import 'si005.dart' as screen005;

void main() {
  runApp(const WorthApp());
}

class WorthApp extends StatelessWidget {
  const WorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'si002',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================
  // AppBar（左上ロゴのみ＋中央タイトル）
  // =========================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showAppName = width >= 360;
    final double leftWidth = showAppName ? 170 : 64;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: leftWidth,

      // 左上：ロゴ + アプリ名（ここだけ表示）
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) => const Icon(Icons.image_not_supported),
            ),
            if (showAppName) ...[
              const SizedBox(width: 6),
              const Text(
                '旅リアン',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),

      // 中央タイトル（完全中央）
      title: const SizedBox.shrink(),
      flexibleSpace: const SafeArea(
        child: Center(
          child: Text(
            'ログイン',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // レスポンシブレイアウト
  // =========================
  Widget _responsiveBody() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double maxWidth = 520;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 256,
                        decoration: const InputDecoration(
                          hintText: 'メールアドレス',
                          border: UnderlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppMessages.errorEmptyEmail;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        maxLength: 32,
                        decoration: InputDecoration(
                          hintText: 'パスワード',
                          border: const UnderlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppMessages.errorEmptyPassword;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const screen003.PasswordReset(),
                              ),
                            );
                          },
                          child: const Text('パスワードを忘れた方はこちら'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text('ログイン'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const screen004.RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('アカウント新規作成'),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _responsiveBody());
  }

  // =========================
  // ログイン処理
  // =========================
  Future<void> _handleLogin() async {
    setState(() => errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse(ApiEndpoints.login);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailAddress': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode != 200) {
        setState(() => errorMessage = AppMessages.errorSystemException);
        return;
      }

      final json = jsonDecode(response.body);
      if (json['result'] == LoginResultCodes.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', json['token']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const screen005.TopScreen()),
        );
      } else {
        setState(() => errorMessage = AppMessages.errorInvalid);
      }
    } catch (_) {
      setState(() => errorMessage = AppMessages.errorSystemException);
    }
  }
}
