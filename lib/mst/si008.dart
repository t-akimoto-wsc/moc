import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// ===============================
/// 単体起動用 main()
/// （flutter run -t lib/si008.dart で確認できる）
/// ===============================
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PasswordChangeScreen(),
    ),
  );
}

/// SI008：パスワード変更
class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  /// 背景色：SI002等と同じトーン
  static const Color _bg = Color(0xFFFFFBFE);

  final _formKey = GlobalKey<FormState>();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String? message; // 画面項目No.10（デフォルト非表示）
  bool _isSubmitting = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================
  // AppBar（戻る＋中央タイトル）
  // =========================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      surfaceTintColor: _bg,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        tooltip: '戻る',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const SizedBox.shrink(),
      flexibleSpace: const SafeArea(
        child: Center(
          child: Text(
            'パスワード変更',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // =========================
  // バリデーション（詳細設計で文言・条件は調整OK）
  // =========================
  String? _validateCurrentPassword(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return AppMessages.errorEmptyPassword;
    if (t.length > 32) return AppMessages.errorPasswordLengthLong;
    return null;
  }

  String? _validateNewPassword(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return AppMessages.errorEmptyPassword;

    // 既存の Register と同じポリシーで揃える（constants.dart の RegexPatterns を利用）
    if (t.length < 8) return AppMessages.errorPasswordLengthShort;
    if (t.length > 32) return AppMessages.errorPasswordLengthLong;
    if (!RegexPatterns.passwordLower.hasMatch(t)) {
      return AppMessages.errorPasswordRequireLower;
    }
    if (!RegexPatterns.passwordUpper.hasMatch(t)) {
      return AppMessages.errorPasswordRequireUpper;
    }
    if (!RegexPatterns.passwordNumber.hasMatch(t)) {
      return AppMessages.errorPasswordRequireNumber;
    }
    if (!RegexPatterns.passwordAllowedChars.hasMatch(t)) {
      return AppMessages.errorPasswordInvalidChar;
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return AppMessages.errorEmptyConfirmPassword;
    if (t != newPasswordController.text.trim())
      return AppMessages.errorNotMatch;
    return null;
  }

  // =========================
  // パスワードポリシー（ロックしない）
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
              onPressed: () => Navigator.of(context).pop(),
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
  Future<void> _showCompletedDialog({required bool success}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true, // ✅ ロックしない
      builder: (context) {
        return AlertDialog(
          title: Text(success ? '変更完了' : '変更失敗'),
          content: Text(
            success
                ? 'パスワードを変更しました。'
                : 'パスワード変更に失敗しました。\n入力内容をご確認のうえ再度お試しください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // DB_パスワード変更（モック実装）
  // ※ApiEndpoints に SI008 が未定義でもコンパイルできるように、
  //   ここでは仮URLを置いています。実APIが決まったら差し替えてください。
  // =========================
  static const String _mockPasswordModifyUrl =
      'https://example.com/password_modify';

  Future<void> _onChangePassword() async {
    FocusScope.of(context).unfocus();
    setState(() => message = null);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => message = AppMessages.errorInvalidInput);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      // ✅ JWT必須の想定：Authorization を付与（無ければ空でも送る）
      final res = await http.put(
        Uri.parse(_mockPasswordModifyUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPasswordController.text,
          'newPassword': newPasswordController.text,
        }),
      );

      // ✅ ここは仕様確定後に resultCode 判定へ置換
      if (res.statusCode == 200) {
        // 可能なら新トークン差し替え（返ってこない場合はスキップ）
        try {
          final json = jsonDecode(res.body);
          final newToken = (json['token'] ?? '').toString();
          if (newToken.isNotEmpty) {
            await prefs.setString('jwt_token', newToken);
          }
        } catch (_) {
          // レスポンスがJSONでない等でも成功扱いは維持
        }

        // 入力値クリア（画面項目 No.3,5,7）
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        if (!mounted) return;
        await _showCompletedDialog(success: true);
      } else {
        if (!mounted) return;
        setState(() => message = 'パスワード変更に失敗しました');
        await _showCompletedDialog(success: false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => message = AppMessages.errorSystemException);
      await _showCompletedDialog(success: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // =========================
  // 画面（レスポンシブ）
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
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
                        const SizedBox(height: 28),

                        // 3: 現在のパスワード
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          maxLength: 32,
                          decoration: InputDecoration(
                            hintText: '現在のパスワード',
                            border: const UnderlineInputBorder(),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureCurrent
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () => setState(
                                    () => obscureCurrent = !obscureCurrent,
                                  ),
                            ),
                          ),
                          validator: _validateCurrentPassword,
                          onChanged: (_) {
                            if (message != null) setState(() => message = null);
                          },
                        ),

                        const SizedBox(height: 16),

                        // 5: 新しいパスワード
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          maxLength: 32,
                          decoration: InputDecoration(
                            hintText: '新しいパスワード',
                            border: const UnderlineInputBorder(),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () =>
                                      setState(() => obscureNew = !obscureNew),
                            ),
                          ),
                          validator: _validateNewPassword,
                          onChanged: (_) {
                            if (message != null) setState(() => message = null);
                          },
                        ),

                        const SizedBox(height: 16),

                        // 7: 新しいパスワード確認
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          maxLength: 32,
                          decoration: InputDecoration(
                            hintText: '新しいパスワード確認',
                            border: const UnderlineInputBorder(),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () => setState(
                                    () => obscureConfirm = !obscureConfirm,
                                  ),
                            ),
                          ),
                          validator: _validateConfirmPassword,
                          onChanged: (_) {
                            if (message != null) setState(() => message = null);
                          },
                        ),

                        const SizedBox(height: 8),

                        // 9: パスワードポリシー
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showPolicyDialog,
                            child: const Text(AppMessages.showPolicy),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 10: メッセージ表示（デフォルト非表示）
                        if (message != null)
                          Text(
                            message!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 22),

                        // 11: 変更ボタン（SI002と同じ感覚で）
                        SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onChangePassword,
                            child: Text(_isSubmitting ? '処理中…' : '変更'),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const SizedBox(height: 24),
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
