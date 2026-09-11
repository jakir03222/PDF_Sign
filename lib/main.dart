import 'package:flutter/material.dart';

import 'controllers/home_controller.dart';
import 'views/home_view.dart';
import 'views/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfStampApp());
}

class PdfStampApp extends StatefulWidget {
  const PdfStampApp({super.key});

  @override
  State<PdfStampApp> createState() => _PdfStampAppState();
}

class _PdfStampAppState extends State<PdfStampApp> {
  final HomeController _home = HomeController();

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Sign & Watermark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeView(controller: _home),
    );
  }
}
