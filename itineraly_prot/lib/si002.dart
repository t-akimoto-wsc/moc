import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'si003.dart' as screen003;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const logo_positioned.CommonLogoPositioned(),
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
                            return AppMessages.errorEmptyEmail;
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
                                builder: (context) => const screen003.PasswordReset(),
                              ),
                            );
                          },
                          child: const Text('パスワードを忘れた方はこちら'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(200, 48),
                        ),
                        onPressed: _handleLogin,
                        child: const Text('ログイン'),
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
                            MaterialPageRoute(
                              builder: (context) => const screen004.RegisterScreen(),
                            ),
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
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = AppMessages.errorInvalidInput;
      });
      return;
    }

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
        });
        return;
      }

      final jsonResponse = jsonDecode(response.body);
      final resultCode = jsonResponse['result'];

      if (resultCode == LoginResultCodes.success) {
        final token = jsonResponse['token'];
        if (token == null || token.isEmpty) {
          throw Exception(AppMessages.errorSystemException);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const screen005.TopScreen()),
        );
      } else if (resultCode == LoginResultCodes.emptyInput) {
        setState(() {
          errorMessage = AppMessages.errorEmpty;
        });
      } else if (resultCode == LoginResultCodes.invalidInput1 ||
          resultCode == LoginResultCodes.invalidInput2) {
        setState(() {
          errorMessage = AppMessages.errorInvalid;
        });
      } else {
        setState(() {
          errorMessage = AppMessages.errorSystemException;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = AppMessages.errorSystemException;
      });
    }
  }
}
