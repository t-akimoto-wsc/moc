import 'package:flutter/material.dart';

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
    final width = MediaQuery.of(context).size.width;
    final bool showAppName = width >= 360;
    final double leftWidth = showAppName ? 170 : 64;

    return AppBar(
      backgroundColor: _bg,
      surfaceTintColor: _bg,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: leftWidth,
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
      body: _responsiveBody(),
    );
  }
}
