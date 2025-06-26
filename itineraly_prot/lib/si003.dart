import 'package:flutter/material.dart';
import 'widgets/common_logo_positioned.dart' as logo_positioned;
import 'si002.dart' as screen002;

class PasswordReset extends StatelessWidget {
  const PasswordReset({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const logo_positioned.CommonLogoPositioned(),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: Colors.orangeAccent,
                ),
                SizedBox(height: 20),
                Text(
                  'この画面は現在作成中です。',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'しばらくお待ちください。',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const screen002.LoginScreen(),
                    ),
                  );
                },
                child: const Text('ログイン画面へ戻る'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
