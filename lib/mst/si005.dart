import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'si002.dart' as screen002;
// SI006 が存在する前提（未作成なら import 行をコメントアウトしてOK）
import 'si006.dart' as screen006;

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: TopScreen()),
  );
}

/// =======================================
/// SI005 ワンタイムパス入力
/// - 既存の遷移先: const screen005.TopScreen() に合わせて
///   クラス名を TopScreen のままにする
/// =======================================
class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen> {
  // SI002/003/004 と同じ背景色（あなたの統一トーン）
  static const Color _bg = Color(0xFFFFFBFE);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();

  String? message; // No.5 メッセージ表示（デフォルト非表示）
  bool _isSending = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  // =========================
  // AppBar（左上ロゴ+旅リアン / 中央タイトル完全中央）
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
            'ワンタイムパス入力',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // バリデーション（軽め）
  // =========================
  String? _validateOtp(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'ワンタイムパスワードを入力してください';

    // 6桁想定（仕様が違うならここだけ変更）
    if (t.length != 6) return 'ワンタイムパスワードは6桁で入力してください';
    if (!RegExp(r'^\d+$').hasMatch(t)) return '数字のみで入力してください';

    return null;
  }

  // =========================
  // 送信（モック）
  // - いまは画面優先でコンパイル通す
  // - APIが決まったら url / body / 判定を差し替え
  // =========================
  Future<void> _onSend() async {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => message = '入力内容を確認してください');
      return;
    }

    setState(() => _isSending = true);

    try {
      // ✅ モックAPI（エンドポイント未確定なので constants.dart に依存しない）
      final url = Uri.parse('https://example.com/otp_verify');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oneTimePassword': otpController.text.trim(),
          // 本来は sessionId 等を入れる（設計通り「メアド再入力不要」）
        }),
      );

      if (!mounted) return;

      // ✅ いまは暫定判定：
      // - 200なら成功扱い（後で resultCode 判定に差し替え）
      if (res.statusCode == 200) {
        await _showCompleteDialog(success: true);
      } else {
        await _showCompleteDialog(success: false);
      }
    } catch (_) {
      if (!mounted) return;
      await _showCompleteDialog(success: false);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // =========================
  // 完了ポップアップ（ロック表示）
  // - 成功: SI006へ
  // - 失敗: 閉じるだけ（メッセージ表示）
  // =========================
  Future<void> _showCompleteDialog({required bool success}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // ロック
      builder: (context) {
        return AlertDialog(
          title: Text(success ? '認証OK' : '認証NG'),
          content: Text(
            success
                ? 'ワンタイムパスの認証が完了しました。'
                : 'ワンタイムパスの認証に失敗しました。\n入力内容をご確認のうえ、再度お試しください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            if (success)
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _goToSi006();
                },
                child: const Text('パスワード設定へ'),
              ),
          ],
        );
      },
    );

    if (!success && mounted) {
      setState(() {
        message = 'ワンタイムパスの認証に失敗しました。';
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
    );
  }

  void _goToSi006() {
    // ✅ SI006 のクラス名が未確定なら、ここだけ合わせればOK
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const screen006.PasswordResetComplete(),
      ),
      // 例）SI006 が PasswordSetScreen なら ↓ に変更
      // MaterialPageRoute(builder: (_) => const screen006.PasswordSetScreen()),
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

                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'ワンタイムパスワード',
                          border: UnderlineInputBorder(),
                          counterText: '',
                        ),
                        validator: _validateOtp,
                        onChanged: (_) {
                          if (message != null) setState(() => message = null);
                        },
                      ),

                      const SizedBox(height: 12),

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

                      // ボタンサイズ：SI002に合わせる（幅220 高さ48）
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
