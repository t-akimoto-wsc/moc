import 'package:flutter/material.dart';
import 'si002.dart' as screen002;
import 'si003.dart' as screen003;
import 'si004.dart' as screen004;
import 'si006.dart' as screen006;

/// ===============================
/// 遷移元種別
/// ===============================
enum OtpFrom {
  PasswordReset,
  RegisterScreen,
}

/// ===============================
/// 単体起動用 main()
/// ===============================
void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OtpScreen(from: OtpFrom.RegisterScreen)),
  );
}

/// =======================================
/// SI005 ワンタイムパス入力（モック）
/// - 送信ボタン押下で SI006（パスワード設定）へ遷移
/// =======================================
class OtpScreen extends StatefulWidget {
  final OtpFrom from;

  const OtpScreen({super.key, required this.from});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();

  String? message;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  /// =========================
  /// 前画面へ戻る
  /// =========================
  void _goBack() {
    if (widget.from == OtpFrom.RegisterScreen) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const screen004.RegisterScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const screen003.PasswordReset(),
        ),
      );
    }
  }

  // =========================
  // AppBar（左上ロゴのみ＋中央タイトル）
  // =========================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showAppName = width >= 360;
    final double leftWidth = showAppName ? 170 : 64;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: leftWidth,

      // 左上：ロゴ + アプリ名
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

      // 中央タイトル
      title: const SizedBox.shrink(),
      flexibleSpace: const SafeArea(
        child: Center(
          child: Text(
            'ワンタイムパス入力',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // バリデーション
  // =========================
  String? _validateOtp(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'ワンタイムパスワードを入力してください';
    return null;
  }

  // =========================
  // 送信（モック）
  // =========================
  void _onSendMock() {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const screen006.PasswordSetScreen(),
      ),
    );
  }

  // =========================
  // 本体
  // =========================
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

                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          decoration: const InputDecoration(
                            hintText: 'ワンタイムパスワード',
                            border: UnderlineInputBorder(),
                            counterText: '',
                          ),
                          validator: _validateOtp,
                          onChanged: (_) {
                            if (message != null) {
                              setState(() => message = null);
                            }
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

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: _goBack,
                          child: const Text('前の画面へ戻る'),
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
