import 'package:flutter/material.dart';
import 'si002.dart' as screen002;

/// ===============================
/// SI001：トップ画面（モック）
/// 起動したら自動で SI002（ログイン）へ遷移
/// ===============================
void main() {
  runApp(const WorthApp());
}

class WorthApp extends StatelessWidget {
  const WorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅リアン',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const StartupScreen(), // ✅ SI001（起動画面）
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  // 他画面と同トーンに合わせる（今の統一色）
  static const Color _bg = Color(0xFFFFFBFE);

  bool _moved = false;

  @override
  void initState() {
    super.initState();
    // 1フレーム後に遷移（context安全）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goLogin();
    });
  }

  void _goLogin() {
    if (_moved) return;
    _moved = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ “表示ほぼ無し” 要件：真っ白（統一色）のみ
    return const Scaffold(backgroundColor: _bg, body: SizedBox.expand());
  }
}
