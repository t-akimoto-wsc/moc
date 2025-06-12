import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

void main() {
  runApp(const WorthApp());
}

class WorthApp extends StatelessWidget {
  const WorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worth Login',
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

  static const String errorInvalid = 'メールアドレスまたはパスワードが間違っています';
  static const String errorEmpty = 'メールアドレスまたはパスワードが未入力です';
  String? errorMessage;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 40, height: 40),
                const SizedBox(width: 8),
                const Text(
                  '旅リアン',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        maxLength: 256,
                        style: const TextStyle(color: Colors.black, fontSize: 14.0),
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
                        style: const TextStyle(color: Colors.black, fontSize: 14.0),
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
                        child: isLoading
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
                        onPressed: () {},
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

      final url = Uri.parse('$baseUrl/login.php');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'emailAddress': email, 'password': password}),
        );

        if (response.statusCode != 200) {
          setState(() {
            errorMessage = 'システムエラーが発生しました。管理者に連絡してください (err=HTTP)';
            isLoading = false;
          });
          return;
        }

        final jsonResponse = jsonDecode(response.body);
        final resultCode = jsonResponse['result'];

        if (resultCode == 1) {
          final token = jsonResponse['token'];
          if (token == null || token.isEmpty) {
            throw Exception('Token missing');
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          setState(() {
            isLoading = false;
            errorMessage = null;
          });

          // TODO: 認証成功時の画面遷移処理
        } else if (resultCode == 50) {
          setState(() {
            errorMessage = errorEmpty;
            isLoading = false;
          });
        } else if (resultCode == 51 || resultCode == 52) {
          setState(() {
            errorMessage = errorInvalid;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
            'システムエラーが発生しました。管理者に連絡してください (err=$resultCode)';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          errorMessage =
          'システムエラーが発生しました。管理者に連絡してください (err=Exception)';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = errorEmpty;
        isLoading = false;
      });
    }
  }
}
