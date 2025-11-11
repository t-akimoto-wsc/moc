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
  final TextEditingController confirmPasswordController =
  TextEditingController();

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
                          final trimmed = value.trim();
                          if (trimmed.length < 3) {
                            return 'メールアドレスは3文字以上で入力してください';
                          }
                          if (trimmed.length > 256) {
                            return 'メールアドレスは256文字以内で入力してください';
                          }
                          if (!RegexPatterns.email.hasMatch(trimmed)) {
                            return AppMessages.errorInvalidEmailFormat;
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
                          final password = value.trim();
                          if (password.length < 8) {
                            return AppMessages.errorPasswordLengthShort;
                          }
                          if (password.length > 32) {
                            return AppMessages.errorPasswordLengthLong;
                          }
                          if (!RegexPatterns.passwordLower.hasMatch(password)) {
                            return AppMessages.errorPasswordRequireLower;
                          }
                          if (!RegexPatterns.passwordUpper.hasMatch(password)) {
                            return AppMessages.errorPasswordRequireUpper;
                          }
                          if (!RegexPatterns.passwordNumber.hasMatch(
                            password,
                          )) {
                            return AppMessages.errorPasswordRequireNumber;
                          }
                          if (!RegexPatterns.passwordAllowedChars.hasMatch(
                            password,
                          )) {
                            return AppMessages.errorPasswordInvalidChar;
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        autocorrect: false,
                        maxLength: 32,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                        decoration: InputDecoration(
                          hintText: 'パスワード（確認）',
                          border: const UnderlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword =
                                !obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppMessages.errorEmptyConfirmPassword;
                          }
                          if (value.trim() != passwordController.text.trim()) {
                            return AppMessages.errorNotMatch;
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
                                title: const Text(AppMessages.showPolicy),
                                content: SingleChildScrollView(
                                  child: Text(
                                    PasswordPolicy.description,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text(AppMessages.dialogClose),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text(AppMessages.showPolicy),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(200, 48),
                        ),
                        onPressed: () async {
                          final isValid =
                              _formKey.currentState?.validate() ?? false;
                          if (!isValid) {
                            setState(() {
                              errorMessage = AppMessages.errorInvalidInput;
                            });
                            return;
                          }

                          final resultCode = await _handleRegister();

                          if (!context.mounted || resultCode == null) return;

                          if (resultCode == RegisterResultCodes.success) {
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('登録完了'),
                                  content: const Text(
                                    AppMessages.successDialog,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (!context.mounted) return;

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder:
                                    (context) => const screen002.LoginScreen(),
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14.0,
                          ),
                        ),
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const screen002.LoginScreen(),
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
        body: jsonEncode({'emailAddress': email, 'password': password}),
      );

      final jsonResponse = jsonDecode(response.body);
      final resultCode = jsonResponse['result'];

      if (resultCode == RegisterResultCodes.success) {
        setState(() {
          errorMessage = null;
        });
      } else if (resultCode == RegisterResultCodes.emptyInput) {
        setState(() {
          errorMessage = AppMessages.errorEmpty;
        });
      } else if (resultCode == RegisterResultCodes.invalidInput1 ||
          resultCode == RegisterResultCodes.invalidInput2) {
        setState(() {
          errorMessage = AppMessages.errorInvalid;
        });
      } else if (resultCode == RegisterResultCodes.alreadyRegistered) {
        setState(() {
          errorMessage = AppMessages.errorRegistered;
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
  }
}
