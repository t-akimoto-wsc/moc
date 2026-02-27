import 'package:flutter/material.dart';

import 'si002.dart' as screen002;
import 'si009.dart' as screen009;

const double kBottomNavHeight = 64;

void main() {
  runApp(const _Si007RunnerApp());
}

class _Si007RunnerApp extends StatelessWidget {
  const _Si007RunnerApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'si007',
      theme: ThemeData(useMaterial3: true),
      home: const Screen007Page(),
    );
  }
}

/// ✅ プロフィール管理（si007）
class Screen007Page extends StatefulWidget {
  const Screen007Page({super.key});

  @override
  State<Screen007Page> createState() => _Screen007PageState();
}

class _Screen007PageState extends State<Screen007Page> {
  static const Color _bg = Color(0xFFFFFBFE);

  // モック（実アプリではログインユーザー情報から差し込み）
  final String _email = 'sample@worth-sc.jp';
  final TextEditingController _nameController = TextEditingController(text: '');

  // ✅ 下部メニューの選択状態（プロフィール=1）
  int _menuIndex = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

      // 左：ロゴ＋旅リアン
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

      // ✅ 右上に出るメニューの温床は actions / flexibleSpace / title内Row右側
      // ✅ ここでは「actions を空固定」し、右側に何も出ないことを保証する
      actions: const [],

      // ✅ タイトルはAppBarの正規のtitleを使う（flexibleSpaceは使わない）
      centerTitle: true,
      title: const Text(
        'プロフィール管理',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  /// ✅ 下部メニュー（2項目）
  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: SizedBox(
          height: kBottomNavHeight,
          child: BottomNavigationBar(
            currentIndex: _menuIndex,
            type: BottomNavigationBarType.fixed,
            onTap: _onTapMenu,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: '旅行情報一覧',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'プロフィール',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapMenu(int index) {
    if (index == _menuIndex) return;

    setState(() => _menuIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const screen009.TripPlanListPage()),
      );
      return;
    }
    // index==1 はプロフィール（現在画面）
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 画面外タップで閉じない
      builder: (context) {
        return AlertDialog(
          title: const Text('ログアウト'),
          content: const Text('ログアウトしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _logoutToLogin();
    }
  }

  void _logoutToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const screen002.LoginScreen()),
      (route) => false,
    );
  }

  Widget _body(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              0,
              24,
              kBottomNavHeight + 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // プロフィール画像（任意）※モック
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 44),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filledTonal(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('（モック）画像選択')),
                            );
                          },
                          icon: const Icon(Icons.camera_alt),
                          tooltip: '写真を変更',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('名前またはニックネーム（必須）', style: TextStyle(fontSize: 12)),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: '表示名',
                    border: UnderlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                const Text('メールアドレス', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: Text(_email, style: const TextStyle(fontSize: 14)),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('（モック）保存しました')),
                      );
                    },
                    child: const Text('保存'),
                  ),
                ),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _confirmLogout,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'ログアウト',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: _body(context),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
