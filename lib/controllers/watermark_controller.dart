import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_repository.dart';
import '../models/picked_pdf.dart';
import '../models/watermark_model.dart';

class WatermarkController extends ChangeNotifier {
  WatermarkController({
    required this.source,
    PdfRepository? repository,
  }) : _repository = repository ?? PdfRepository() {
    model.toPage = totalPages;
  }

  final PickedPdf source;
  final PdfRepository _repository;
  final WatermarkModel model = WatermarkModel();

  int tabIndex = 0;
  bool saving = false;
  String? error;
  File? output;

  int get totalPages {
    try {
      final document = PdfDocument(inputBytes: source.bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (_) {
      return 0;
    }
  }

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void setText(String value) {
    model.text = value;
    notifyListeners();
  }

  void setImage({required Uint8List bytes, required String name}) {
    model.imageBytes = bytes;
    model.imageName = name;
    notifyListeners();
  }

  void clearImage() {
    model.imageBytes = null;
    model.imageName = null;
    notifyListeners();
  }

  void setError(String message) {
    error = message;
    notifyListeners();
  }

  void setFamily(String value) {
    model.family = value;
    notifyListeners();
  }

  void setSize(double value) {
    model.size = value.clamp(8, 72);
    notifyListeners();
  }

  void setStyle(WatermarkStyle style) {
    model.style = style;
    notifyListeners();
  }

  void setColor(Color color) {
    model.color = color;
    notifyListeners();
  }

  void setHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) {
      return;
    }
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) {
      return;
    }
    model.color = Color(0xFF000000 | value);
    notifyListeners();
  }

  void setOpacity(double value) {
    model.opacity = value.clamp(0, 1);
    notifyListeners();
  }

  void setRotation(double value) {
    model.rotation = value;
    notifyListeners();
  }

  void setPageRange({int? from, int? to}) {
    model.fromPage = from ?? model.fromPage;
    model.toPage = to ?? model.toPage;
    notifyListeners();
  }

  void setLayer(WatermarkLayer layer) {
    model.layer = layer;
    notifyListeners();
  }

  void setPosition(Offset relative) {
    model.relativePosition = Offset(
      relative.dx.clamp(0.1, 0.9),
      relative.dy.clamp(0.1, 0.9),
    );
    notifyListeners();
  }

  Future<File?> apply() async {
    if (totalPages == 0) {
      error = 'The selected file is not a readable PDF.';
      notifyListeners();
      return null;
    }
    if (model.fromPage < 1 || model.fromPage > model.toPage || model.toPage > totalPages) {
      error = 'Page range must be between 1 and $totalPages.';
      notifyListeners();
      return null;
    }
    if (tabIndex == 1 && !model.hasImage) {
      error = 'Choose an image for the watermark first.';
      notifyListeners();
      return null;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      output = await _repository.stampWatermark(
        source: source,
        watermark: model,
      );
      saving = false;
      notifyListeners();
      return output;
    } catch (e) {
      error = 'Could not watermark the PDF: $e';
      saving = false;
      notifyListeners();
      return null;
    }
  }
}
