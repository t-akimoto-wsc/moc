import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'si002.dart' as screen002;
import 'si006.dart' as screen006;

/// ===============================
/// SI003 パスワード再設定
/// - si002 と同じ観点で統一
/// - si002.dart から screen003.PasswordReset() で遷移できる
/// ===============================
class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  // ✅ 背景色（採用したトーン）
  static const Color _bg = Color(0xFFFFFBFE);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  bool _isSending = false;
  String? errorMessage; // 画面項目No.5（デフォルト非表示）

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // =========================
  // AppBar（si002と同じ：左上ロゴのみ＋中央タイトル完全中央）
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
            'パスワード再設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // バリデーション（詳細設計で厳密化する前提で軽め）
  // =========================
  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'メールアドレスを入力してください';
    if (t.length > 256) return '256文字以内で入力してください';
    if (!t.contains('@') || !t.contains('.')) {
      return 'メールアドレスの形式が正しくありません';
    }
    return null;
  }

  // =========================
  // 送信処理：ポップアップ無し → SI006へ
  // =========================
  Future<void> _onSend() async {
    FocusScope.of(context).unfocus();
    setState(() => errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => errorMessage = '入力内容を確認してください');
      return;
    }

    setState(() => _isSending = true);

    try {
      // ✅ ここはモック（エンドポイントが決まったら差し替え）
      // 仕様：ユーザー列挙防止のため、存在しないメールでも成功扱いのレスポンスを返す想定
      final url = Uri.parse('https://example.com/password_reset');

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailAddress': emailController.text.trim()}),
      );

      if (!mounted) return;

      // ✅ 完了画面 SI006 へ（メール渡し）
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => screen006.PasswordResetComplete(
                emailAddress: emailController.text.trim(),
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = '送信に失敗しました。時間をおいて再度お試しください。');
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
  // Body（si002と同じ雰囲気：maxWidth, Underline, 文字サイズ）
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
                    children: [
                      const SizedBox(height: 40),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 256,
                        style: const TextStyle(fontSize: 14.0),
                        decoration: const InputDecoration(
                          hintText: 'メールアドレス',
                          border: UnderlineInputBorder(),
                          counterText: '',
                        ),
                        validator: _validateEmail,
                        onChanged: (_) {
                          if (errorMessage != null) {
                            setState(() => errorMessage = null);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 24),

                      // ✅ ボタンサイズ：si002に合わせる（fixedSize感）
                      SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _onSend,
                          child: Text(_isSending ? '送信中…' : '送信'),
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
