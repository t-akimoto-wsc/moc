import 'package:flutter/material.dart';

class TopScreen extends StatelessWidget {
  const TopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トップ画面'),
      ),
      body: const Center(
        child: Text('ここがトップ画面です'),
      ),
    );
  }
}
