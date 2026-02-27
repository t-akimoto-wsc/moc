import 'package:flutter/material.dart';
import 'si002.dart' as screen002;
import 'si005.dart' as screen005;

// ===============================
// 単体起動用 main()
// ===============================
void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: PasswordReset()),
  );
}

/// =======================================
/// SI003（モック）パスワード再設定
/// - 送信ボタン押下 → SI005(OTP)へ遷移（モックなので入力チェックしない）
/// - クラス名は呼び出し側に合わせて PasswordReset 固定
/// =======================================
class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  String? message;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // AppBar（左上ロゴ＋アプリ名、中央タイトル完全中央）
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showAppName = width >= 360;
    final double leftWidth = showAppName ? 170 : 64;

    return AppBar(
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
            'パスワード再設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ✅ モック：ボタン押したら必ず OTP へ
  void _onSendMock() {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const screen005.OtpScreen()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
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

                        // 仕様上は必須入力だけど、モックでは遷移条件にしない
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 256,
                          decoration: const InputDecoration(
                            hintText: 'メールアドレス',
                            border: UnderlineInputBorder(),
                            counterText: '',
                          ),
                          onChanged: (_) {
                            if (message != null) setState(() => message = null);
                          },
                        ),

                        const SizedBox(height: 20),

                        if (message != null)
                          Text(
                            message!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _onSendMock,
                            child: const Text('送信'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: _goToLogin,
                          child: const Text('ログイン画面へ戻る'),
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
      ),
    );
  }
}
