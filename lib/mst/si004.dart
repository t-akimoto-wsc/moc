import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'si002.dart' as screen002;
import 'si005.dart' as screen005;

/// ===============================
/// 単体起動用 main()
/// ===============================
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  String? message; // 画面項目No.5（デフォルト非表示）
  bool _isSending = false;

  @override
  void dispose() {
    emailController.dispose();
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
      backgroundColor: _bg,
      surfaceTintColor: _bg,
      elevation: 0,
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
            'アカウント作成',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // バリデーション（詳細設計で厳密化OK）
  // ※ constants.dart の RegexPatterns.email がある想定
  // =========================
  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AppMessages.errorEmptyEmail;
    if (v.length < 3) return 'メールアドレスは3文字以上で入力してください';
    if (v.length > 256) return 'メールアドレスは256文字以内で入力してください';

    // RegexPatterns.email が無い場合は、下の簡易判定に差し替えてOK
    // if (!v.contains('@') || !v.contains('.')) return AppMessages.errorInvalidEmailFormat;
    if (!RegexPatterns.email.hasMatch(v))
      return AppMessages.errorInvalidEmailFormat;

    return null;
  }

  // =========================
  // 送信（設計：存在済みメアドはエラー）
  // OK→SI005へ
  // =========================
  Future<void> _onSend() async {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => message = AppMessages.errorInvalidInput);
      return;
    }

    setState(() => _isSending = true);

    try {
      final url = Uri.parse(ApiEndpoints.register); // 既存のregisterエンドポイントを流用想定
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailAddress': emailController.text.trim()}),
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() => message = AppMessages.errorSystemException);
        return;
      }

      final json = jsonDecode(res.body);
      final result = json['result'];

      // resultCode は constants.dart の RegisterResultCodes を前提
      if (result == RegisterResultCodes.success) {
        // ✅ OK → SI005（ワンタイムパス入力）へ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const screen005.TopScreen()),
        );
        return;
      }

      // ✅ SI004は「存在済みメアドはエラーで返す」
      if (result == RegisterResultCodes.alreadyRegistered) {
        setState(() => message = AppMessages.errorRegistered);
        return;
      }

      if (result == RegisterResultCodes.emptyInput) {
        setState(() => message = AppMessages.errorEmpty);
        return;
      }

      if (result == RegisterResultCodes.invalidInput1 ||
          result == RegisterResultCodes.invalidInput2) {
        setState(() => message = AppMessages.errorInvalid);
        return;
      }

      setState(() => message = AppMessages.errorSystemException);
    } catch (_) {
      if (!mounted) return;
      setState(() => message = AppMessages.errorSystemException);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
    );
  }

  // =========================
  // レスポンシブボディ
  // =========================
  Widget _responsiveBody() {
    return SafeArea(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // No.4 メールアドレス
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        maxLength: 256,
                        decoration: const InputDecoration(
                          hintText: 'メールアドレス',
                          border: UnderlineInputBorder(),
                          counterText: '',
                        ),
                        validator: _validateEmail,
                        onChanged: (_) {
                          if (message != null) {
                            setState(() => message = null);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // No.5 メッセージ表示（デフォルト非表示）
                      if (message != null) ...[
                        Text(
                          message!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 24),

                      // No.6 送信（サイズはSI002と合わせ）
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _onSend,
                            child: Text(_isSending ? '送信中…' : '送信'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // No.7 ログイン画面リンク
                      Center(
                        child: TextButton(
                          onPressed: _goToLogin,
                          child: const Text('ログイン画面へ戻る'),
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
