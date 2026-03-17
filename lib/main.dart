import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'si002.dart' as screen002;

/// ===============================
/// SI001：トップ画面
/// 背景画像 + タップでログイン画面へ遷移
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

      // 日本語ロケール設定
      locale: const Locale('ja'),
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _moved = false;

  void _goLogin() {
    if (_moved) return;
    _moved = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const screen002.LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goLogin,
      child: Scaffold(
        body: Stack(
          children: [

            /// 背景画像
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Topimage.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// 文字を見やすくする半透明レイヤー
            Container(
              color: Colors.black.withOpacity(0.35),
            ),

            /// 中央テキスト
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [

                  Icon(
                    Icons.flight_outlined,
                    color: Colors.white,
                    size: 100,
                  ),

                  SizedBox(height: 30),

                  Text(
                    '旅リアン',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    '画面をタップしてください',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}