import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'si002.dart' as screen002;
import 'widgets/common_logo_positioned.dart' as logo_positioned;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
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
                padding: const EdgeInsets.all(16.0),
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
                            return 'メールアドレスが未入力です。';
                          }
                          final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return '正しいメールアドレスの形式で入力してください。';
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
                            icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'パスワードが未入力です。';
                          }
                          final password = value.trim();
                          if (password.length < 8) {
                            return 'パスワードは8文字以上で入力してください。';
                          }
                          if (password.length > 32) {
                            return 'パスワードは32文字以内で入力してください。';
                          }
                          if (!RegExp(r'[a-z]').hasMatch(password)) {
                            return 'パスワードには英小文字を1文字以上含めてください。';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(password)) {
                            return 'パスワードには英大文字を1文字以上含めてください。';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(password)) {
                            return 'パスワードには数字を1文字以上含めてください。';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9`~!@#\$%\^&\*\(\)_\+\-=\{\}\[\]\\|:;\"<>,\.\?\/]+$').hasMatch(password)) {
                            return '使用できない文字が含まれています';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        autocorrect: false,
                        maxLength: 32,
                        style: const TextStyle(color: Colors.black, fontSize: 14.0),
                        decoration: InputDecoration(
                          hintText: 'パスワード（確認）',
                          border: const UnderlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword = !obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'パスワード（確認）が未入力です。';
                          }
                          if (value.trim() != passwordController.text.trim()) {
                            return 'パスワードと一致しません。';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('パスワードポリシー'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    '■ 文字数：8文字以上～32文字以下\n'
                                        '■ 条件：英小文字、英大文字、数字を最低1文字ずつ使用\n'
                                        '■ 使用可能な文字：\n'
                                        '・半角英数字（a〜z, A〜Z, 0〜9）\n'
                                        '\n'
                                        '・使用可能な記号：\n'
                                        '` ˜ ! @ # \$ % ^ & * ( ) _ + - = { } [ ]\n'
                                        '| : ; " < > , . ? /\n',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('閉じる'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('パスワードポリシー'),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(fixedSize: const Size(200, 48)),
                        onPressed: () async {
                          final isValid = _formKey.currentState?.validate() ?? false;
                          if (!isValid) {
                            setState(() {
                              errorMessage = '入力項目の内容に問題があります';
                            });
                            return;
                          }

                          final resultCode = await _handleRegister();

                          if (!context.mounted || resultCode == null) return;

                          if (resultCode == 1) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const screen002.LoginScreen(),
                              ),
                            );
                          }
                        },
                        child: const Text('作成'),
                      ),
                      const SizedBox(height: 30),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14.0),
                        ),
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const screen002.LoginScreen(),
                              ),
                            );
                          },
                          child: const Text('ログイン画面へ戻る'),
                        ),
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

  Future<int?> _handleRegister() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final url = Uri.parse(ApiEndpoints.register);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'EmailAddress': email, 'Password': password}),
      );

      final jsonResponse = jsonDecode(response.body);
      final resultCode = jsonResponse['result'];

      if (resultCode == 1) {
        setState(() {
          errorMessage = null;
        });
      } else if (resultCode == 50) {
        setState(() {
          errorMessage = 'メールアドレスまたはパスワードが未入力です。';
        });
      } else if (resultCode == 51 || resultCode == 52) {
        setState(() {
          errorMessage = 'メールアドレスまたはパスワードが不正です。';
        });
      } else if (resultCode == 53) {
        setState(() {
          errorMessage = 'このメールアドレスは既に登録されています。';
        });
      } else {
        setState(() {
          errorMessage = 'システムエラーが発生しました。';
        });
      }

      return resultCode;
    } catch (_) {
      setState(() {
        errorMessage = 'システムエラーが発生しました。';
      });
      return null;
    }
  }
}
