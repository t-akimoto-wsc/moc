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
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント登録')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'パスワード'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(200, 48),
                  ),
                  onPressed: () async {
                    final isValid = _formKey.currentState?.validate() ?? false;
                    if (isValid) {
                      final resultCode = await _handleRegister();
                      if (resultCode == 1) {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('アカウント作成'),
                              content: const Text('アカウントが正常に作成されました'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } else {
                      setState(() {
                        errorMessage = '入力項目の内容に問題があります';
                      });
                    }
                  },
                  child: const Text('作成'),
                ),
                const SizedBox(height: 30),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14.0,
                    ),
                  ),
                const SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('ログイン画面へ戻る'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int?> _handleRegister() async {
    setState(() {
      errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final url = Uri.parse(ApiEndpoints.register);

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'emailAddress': email, 'password': password}),
        );

        final jsonResponse = jsonDecode(response.body);
        final resultCode = jsonResponse['result'];

        if (resultCode == 1) {
          setState(() {
            errorMessage = null;
          });

          return resultCode;
        } else if (resultCode == 50) {
          setState(() {
            errorMessage = AppMessages.errorEmpty;
          });
        } else if (resultCode == 51 || resultCode == 52) {
          setState(() {
            errorMessage = AppMessages.errorInvalid;
          });
        } else {
          setState(() {
            errorMessage = AppMessages.errorSystemException;
          });
        }

        return resultCode;
      } catch (_) {
        setState(() {
          errorMessage = AppMessages.errorSystemException;
        });
        return null;
      }
    } else {
      setState(() {
        errorMessage = AppMessages.errorEmpty;
      });
      return null;
    }
  }
}
