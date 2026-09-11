import 'dart:typed_data';

import 'package:flutter/material.dart';

enum WatermarkStyle { regular, italic, bold, boldItalic }

enum WatermarkLayer { overContent, underContent }

class WatermarkModel {
  WatermarkModel({
    this.text = '',
    this.family = 'Helvetica',
    this.size = 14,
    this.style = WatermarkStyle.regular,
    this.color = const Color(0xFFE53935),
    this.opacity = 0.35,
    this.rotation = -45,
    this.fromPage = 1,
    this.toPage = 1,
    this.layer = WatermarkLayer.overContent,
    this.relativePosition = const Offset(0.5, 0.5),
    this.imageBytes,
    this.imageName,
  });

  String text;
  String family;
  double size;
  WatermarkStyle style;
  Color color;
  double opacity;
  double rotation;
  int fromPage;
  int toPage;
  WatermarkLayer layer;
  Offset relativePosition;
  Uint8List? imageBytes;
  String? imageName;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  static const families = <String>['Helvetica', 'Times', 'Courier'];

  String get displayText => text.trim().isEmpty ? 'Watermark' : text.trim();

  FontWeight get fontWeight =>
      style == WatermarkStyle.bold || style == WatermarkStyle.boldItalic
          ? FontWeight.w700
          : FontWeight.w400;

  FontStyle get fontStyle =>
      style == WatermarkStyle.italic || style == WatermarkStyle.boldItalic
          ? FontStyle.italic
          : FontStyle.normal;

  String get hex =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
