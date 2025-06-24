import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'si004.dart' as screen004;
import 'si005.dart' as screen005;
import 'widgets/common_logo_positioned.dart' as logo_positioned;

void main() {
  runApp(const WorthApp());
}

class WorthApp extends StatelessWidget {
  const WorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'si002',
      theme: ThemeData(primarySwatch: Colors.indigo),
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
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const logo_positioned.CommonLogoPositioned(), // ← ここを修正
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        maxLength: 256,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'メールアドレス',
                          border: UnderlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'メールアドレスが未入力です';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        autocorrect: false,
                        maxLength: 32,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
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
                            return 'パスワードが未入力です';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('パスワードを忘れた方はこちら'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(200, 48),
                        ),
                        onPressed: isLoading ? null : _handleLogin,
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('ログイン'),
                      ),
                      const SizedBox(height: 20),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14.0,
                          ),
                        ),
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const screen004.RegisterScreen()),
                          );
                        },
                        child: const Text('アカウント新規作成'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text;

      final url = Uri.parse(ApiEndpoints.login);

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'emailAddress': email, 'password': password}),
        );

        if (response.statusCode != 200) {
          setState(() {
            errorMessage = AppMessages.errorSystemException;
            isLoading = false;
          });
          return;
        }

        final jsonResponse = jsonDecode(response.body);
        final resultCode = jsonResponse['result'];

        if (resultCode == 1) {
          final token = jsonResponse['token'];
          if (token == null || token.isEmpty) {
            throw Exception(AppMessages.errorSystemException);
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          setState(() {
            isLoading = false;
            errorMessage = null;
          });

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const screen005.TopScreen(),
            ),
          );
        } else if (resultCode == 50) {
          setState(() {
            errorMessage = AppMessages.errorEmpty;
            isLoading = false;
          });
        } else if (resultCode == 51 || resultCode == 52) {
          setState(() {
            errorMessage = AppMessages.errorInvalid;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = AppMessages.errorSystemException;
            isLoading = false;
          });
        }
      } catch (_) {
        setState(() {
          errorMessage = AppMessages.errorSystemException;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = AppMessages.errorEmpty;
        isLoading = false;
      });
    }
  }
}
