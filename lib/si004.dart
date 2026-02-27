import 'package:flutter/material.dart';
import 'si002.dart' as screen002;
import 'si005.dart' as screen005;

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RegisterScreen(),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _bg = Color(0xFFFFFBFE);

  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
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
            'アカウント作成',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void _goToOtpMock() {
    // ✅ 設計の流れに合わせて SI005（OTP入力）へ
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const screen005.OtpScreen()),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxWidth = 520.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 256,
                        decoration: const InputDecoration(
                          hintText: 'メールアドレス',
                          border: UnderlineInputBorder(),
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton(
                          // ✅ モック：押したら必ず次画面
                          onPressed: _goToOtpMock,
                          child: const Text('送信'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: _goToLogin,
                        child: const Text('ログイン画面へ戻る'),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
