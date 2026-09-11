import 'dart:typed_data';

import 'package:flutter/material.dart';

class SignatureFont {
  const SignatureFont({
    required this.id,
    required this.label,
    required this.family,
    required this.asset,
  });

  final String id;
  final String label;
  final String family;
  final String asset;
}

class SignatureModel {
  SignatureModel({
    this.name = '',
    this.fontIndex = 0,
    this.size = 36,
    this.bold = false,
    this.colorIndex = 0,
    this.relativePosition = const Offset(0.5, 0.82),
    this.drawnSignature,
    this.importedSignature,
  });

  String name;
  int fontIndex;
  double size;
  bool bold;
  int colorIndex;

  /// Normalized page position (0–1). Default is bottom-center of page 1.
  Offset relativePosition;
  Uint8List? drawnSignature;
  Uint8List? importedSignature;

  bool get hasDrawnSignature => drawnSignature != null && drawnSignature!.isNotEmpty;
  bool get hasImportedSignature => importedSignature != null && importedSignature!.isNotEmpty;

  Uint8List? get imageSignature => importedSignature ?? drawnSignature;

  static const fonts = <SignatureFont>[
    SignatureFont(
      id: 'great_vibes',
      label: 'Vibes',
      family: 'GreatVibes',
      asset: 'assets/fonts/GreatVibes-Regular.ttf',
    ),
    SignatureFont(
      id: 'pacifico',
      label: 'Pacific',
      family: 'Pacifico',
      asset: 'assets/fonts/Pacifico-Regular.ttf',
    ),
    SignatureFont(
      id: 'allura',
      label: 'Allura',
      family: 'Allura',
      asset: 'assets/fonts/Allura-Regular.ttf',
    ),
    SignatureFont(
      id: 'sacramento',
      label: 'Sacra',
      family: 'Sacramento',
      asset: 'assets/fonts/Sacramento-Regular.ttf',
    ),
    SignatureFont(
      id: 'cookie',
      label: 'Cookie',
      family: 'Cookie',
      asset: 'assets/fonts/Cookie-Regular.ttf',
    ),
  ];

  static const colors = <Color>[
    Color(0xFF111111),
    Color(0xFFC62828),
    Color(0xFFE53935),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF5D4037),
  ];

  SignatureFont get font => fonts[fontIndex.clamp(0, fonts.length - 1)];

  Color get color => colors[colorIndex.clamp(0, colors.length - 1)];
}
