import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const String kAppLogoAsset = 'assets/images/logo.png';

void main() {
  runApp(const ProfileTestApp());
}

class ProfileTestApp extends StatelessWidget {
  const ProfileTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '旅リアン',
      theme: ThemeData(useMaterial3: true),
      home: const Si005Page(),
    );
  }
}

class Si005Page extends StatefulWidget {
  const Si005Page({super.key});

  @override
  State<Si005Page> createState() => _Si005PageState();
}

class _Si005PageState extends State<Si005Page> {
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final birthdayController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  String _savedName = '';
  String _savedContact = '';
  String _savedBirthday = '';
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();
    _markSaved();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  void _markSaved() {
    _savedName = nameController.text;
    _savedContact = contactController.text;
    _savedBirthday = birthdayController.text;
    _savedImagePath = _imageFile?.path;
  }

  bool get _hasUnsavedChanges {
    return nameController.text != _savedName ||
        contactController.text != _savedContact ||
        birthdayController.text != _savedBirthday ||
        (_imageFile?.path) != _savedImagePath;
  }

  Future<bool> _confirmDiscardDialog() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('確認'),
          content: const Text('未保存の変更があります。\nこのまま移動すると入力した情報が失われます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('破棄する'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _onWillPop() async {
    return await _confirmDiscardDialog();
  }

  // ---------------- 写真 ----------------
  void _showImagePickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('現在の写真を削除'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imageFile = null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('キャンセル'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  // ---------------- 生年月日 ----------------
  Future<void> _pickBirthdayDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');

    birthdayController.text = '$yyyy/$mm/$dd';
  }

  Future<void> _onPasswordChangeTap() async {
    final ok = await _confirmDiscardDialog();
    if (!ok) return;

    _showSnack('（モック）パスワード変更画面へ遷移します');
  }

  void _onSave() {
    _markSaved();
    _showSnack('保存しました（モック）');
  }

  // ---------------- AppBar（レスポンシブ） ----------------
  PreferredSizeWidget _buildResponsiveAppBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 狭い端末では左の"旅リアン"を省略して、中央タイトルの見切れを回避
    final bool showAppName = width >= 360;

    // 左ブロックの幅を端末幅に応じて調整（中央タイトルの領域を潰しすぎない）
    final double leftWidth = showAppName ? (width * 0.38).clamp(120, 180) : 64;

    return AppBar(
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leadingWidth: leftWidth,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              kAppLogoAsset,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported);
              },
            ),
            if (showAppName) ...[
              const SizedBox(width: 6),
              // 文字が長くても安全に省略
              const Flexible(
                child: Text(
                  '旅リアン',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),

      // titleは使わず、flexibleSpaceで"画面中央"に絶対配置
      title: const SizedBox.shrink(),
      flexibleSpace: SafeArea(
        child: Stack(
          children: const [
            Center(
              child: Text(
                'プロフィール管理',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _buildResponsiveAppBar(context),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 2,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: '一覧'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: '地図'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // タブレット/横画面で広すぎないよう最大幅を制限
              const double maxContentWidth = 520;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // プロフィール写真
                        Center(
                          child: InkWell(
                            onTap: _showImagePickerMenu,
                            borderRadius: BorderRadius.circular(52),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : null,
                              child:
                                  _imageFile == null
                                      ? const Icon(Icons.person, size: 52)
                                      : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'プロフィール写真',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 24),

                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '名前（任意）',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: '連絡先（任意）',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: birthdayController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: '生年月日（任意）',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: _pickBirthdayDate,
                            ),
                          ),
                          onTap: _pickBirthdayDate,
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _onPasswordChangeTap,
                            child: const Text('パスワード変更はこちら'),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _onSave,
                            child: const Text('保存する'),
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
