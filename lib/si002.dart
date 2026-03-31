import 'package:flutter/material.dart';
import 'widgets/resort_header.dart';

import 'si003.dart' as screen003;
import 'si004.dart' as screen004;
import 'si009.dart' as screen009; // ★追加

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
  static const Color _bg = Color(0xFFFFFBFE);

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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return const ResortHeader(title: 'ログイン');
  }

  Widget _responsiveBody() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'メールアドレス',
                    border: UnderlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'パスワード',
                    border: const UnderlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
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
                    onPressed: _goToHomeMock,
                    child: const Text('ログイン'),
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
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
  }

  // ★ログイン → SI009へ
  void _goToHomeMock() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const screen009.TripPlanListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),

          _responsiveBody(),
        ],
      ),
    );
  }
}
