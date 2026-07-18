import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const SealApp());

class SealApp extends StatelessWidget {
  const SealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ぺたっと',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
