import 'package:flutter/material.dart';
import 'si006.dart' as screen006;

/// ===============================
/// 単体起動用 main()
/// ===============================
void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OtpScreen()),
  );
}

/// =======================================
/// SI005 ワンタイムパス入力（モック）
/// - 送信ボタン押下で SI006（パスワード設定）へ遷移
/// - ※ TopScreen は SI009 予定のため、ここでは定義しない
/// =======================================
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

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

      // 左上：ロゴ + アプリ名（ここだけ表示）
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

      // 中央タイトル（完全中央）
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
  // バリデーション（残しておく：見た目の即時エラー表示用）
  // ※ ただしモック遷移では使わない
  // =========================
  String? _validateOtp(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'ワンタイムパスワードを入力してください';
    return null;
  }

  // =========================
  // 送信（モック）：入力の正誤に関わらず SI006 へ
  // =========================
  void _onSendMock() {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    // ✅ モック方針：バリデーション無視で次へ
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const screen006.PasswordSetScreen()),
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
                          validator: _validateOtp, // 表示用に残す
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
