import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'si002.dart' as screen002;

/// ===============================
/// 単体起動用 main()
/// ===============================
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PasswordSetScreen(),
    ),
  );
}

/// ✅ 互換用（過去の呼び出し名を吸収）
/// 例：screen006.PasswordResetComplete(emailAddress: xxx)
class PasswordResetComplete extends StatelessWidget {
  final String? emailAddress;
  const PasswordResetComplete({super.key, this.emailAddress});

  @override
  Widget build(BuildContext context) {
    return PasswordSetScreen(emailAddress: emailAddress);
  }
}

/// ===============================
/// SI006 パスワード設定
/// ===============================
class PasswordSetScreen extends StatefulWidget {
  final String? emailAddress; // 将来必要なら受け取る（今は未使用）

  const PasswordSetScreen({super.key, this.emailAddress});

  @override
  State<PasswordSetScreen> createState() => _PasswordSetScreenState();
}

class _PasswordSetScreenState extends State<PasswordSetScreen> {
  // ✅ 背景色：SI002 と同じトーン
  static const Color _bg = Color(0xFFFFFBFE);

  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool obscurePassword = true;
  bool obscureConfirm = true;

  String? message; // 画面項目 No.9（デフォルト非表示）
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // ✅ フォーカスアウトでメッセージ欄に出す（設計書のアクションに合わせる）
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) _validateOnFocusOut();
    });
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus) _validateOnFocusOut();
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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

      // 左上：ロゴ + アプリ名（ここだけ）
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
            'パスワード設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // バリデーション（constants.dart に合わせる）
  // =========================
  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AppMessages.errorEmptyPassword;

    if (v.length < 8) return AppMessages.errorPasswordLengthShort;
    if (v.length > 32) return AppMessages.errorPasswordLengthLong;

    if (!RegexPatterns.passwordLower.hasMatch(v)) {
      return AppMessages.errorPasswordRequireLower;
    }
    if (!RegexPatterns.passwordUpper.hasMatch(v)) {
      return AppMessages.errorPasswordRequireUpper;
    }
    if (!RegexPatterns.passwordNumber.hasMatch(v)) {
      return AppMessages.errorPasswordRequireNumber;
    }
    if (!RegexPatterns.passwordAllowedChars.hasMatch(v)) {
      return AppMessages.errorPasswordInvalidChar;
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AppMessages.errorEmptyConfirmPassword;
    if (v != passwordController.text.trim()) return AppMessages.errorNotMatch;
    return null;
  }

  void _validateOnFocusOut() {
    final pErr = _validatePassword(passwordController.text);
    final cErr = _validateConfirm(confirmController.text);

    // ✅ どちらかNGなら No.9 に表示（設計書通り）
    if (pErr != null) {
      setState(() => message = pErr);
      return;
    }
    if (cErr != null) {
      setState(() => message = cErr);
      return;
    }

    // ✅ OKなら消す
    if (message != null) setState(() => message = null);
  }

  // =========================
  // ポリシー（ロックしない）
  // =========================
  Future<void> _showPolicyDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true, // ✅ ロックしない
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text(AppMessages.dialogClose),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // 完了ポップアップ（ロックしない）
  // =========================
  Future<void> _showCompleteDialog({required bool success}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true, // ✅ ロックしない
      builder: (context) {
        return AlertDialog(
          title: Text(success ? '完了' : 'エラー'),
          content: Text(
            success ? 'パスワードを設定しました。' : '処理に失敗しました。時間をおいて再度お試しください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            if (success)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _goToLogin();
                },
                child: const Text('ログイン画面へ'),
              ),
          ],
        );
      },
    );
  }

  // =========================
  // 設定ボタン押下
  // =========================
  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    final pErr = _validatePassword(passwordController.text);
    final cErr = _validateConfirm(confirmController.text);

    if (pErr != null || cErr != null) {
      setState(() => message = pErr ?? cErr);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ✅ モックAPI（後で endpoints に差し替え）
      // メール再入力不要：セッションIDで紐づける想定（設計書備考）
      final url = Uri.parse('https://example.com/password_set');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': passwordController.text.trim(),
          // 'sessionId': '...', // 本来は端末保持のセッションIDを送る
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        await _showCompleteDialog(success: true);
      } else {
        await _showCompleteDialog(success: false);
      }
    } catch (_) {
      if (!mounted) return;
      await _showCompleteDialog(success: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
    );
  }

  // =========================
  // レスポンシブボディ（SI002と同じ）
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

                      // 新しいパスワード
                      TextFormField(
                        controller: passwordController,
                        focusNode: _passwordFocus,
                        obscureText: obscurePassword,
                        maxLength: 32,
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
                        validator: _validatePassword,
                        onChanged: (_) {
                          if (message != null) setState(() => message = null);
                        },
                      ),

                      const SizedBox(height: 16),

                      // パスワード確認
                      TextFormField(
                        controller: confirmController,
                        focusNode: _confirmFocus,
                        obscureText: obscureConfirm,
                        maxLength: 32,
                        decoration: InputDecoration(
                          hintText: 'パスワード（確認）',
                          border: const UnderlineInputBorder(),
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: _validateConfirm,
                        onChanged: (_) {
                          if (message != null) setState(() => message = null);
                        },
                      ),

                      const SizedBox(height: 8),

                      // パスワードポリシー
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showPolicyDialog,
                          child: const Text(AppMessages.showPolicy),
                        ),
                      ),

                      // メッセージ表示（No.9）
                      if (message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          message!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 設定ボタン（SI002と同サイズ）
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onSubmit,
                            child: Text(_isSubmitting ? '処理中…' : '設定'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ログインへ戻る
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
