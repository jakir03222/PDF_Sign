import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/pdf_repository.dart';
import '../models/picked_pdf.dart';
import '../models/signature_model.dart';

class SignatureController extends ChangeNotifier {
  SignatureController({
    required this.source,
    PdfRepository? repository,
  }) : _repository = repository ?? PdfRepository();

  final PickedPdf source;
  final PdfRepository _repository;
  final SignatureModel model = SignatureModel();

  int tabIndex = 0;
  bool saving = false;
  String? error;
  File? output;

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void setName(String value) {
    model.name = value;
    notifyListeners();
  }

  void clearName() {
    model.name = '';
    notifyListeners();
  }

  void setDrawnSignature(Uint8List bytes) {
    model.drawnSignature = bytes;
    notifyListeners();
  }

  void setImportedSignature(Uint8List bytes) {
    model.importedSignature = bytes;
    notifyListeners();
  }

  void clearDrawnSignature() {
    model.drawnSignature = null;
    notifyListeners();
  }

  void clearImportedSignature() {
    model.importedSignature = null;
    notifyListeners();
  }

  void setFont(int index) {
    model.fontIndex = index;
    notifyListeners();
  }

  void setSize(double value) {
    model.size = value.clamp(20, 80);
    notifyListeners();
  }

  void setBold(bool value) {
    model.bold = value;
    notifyListeners();
  }

  void setColor(int index) {
    model.colorIndex = index;
    notifyListeners();
  }

  void setPosition(Offset relative) {
    model.relativePosition = Offset(
      relative.dx.clamp(0.08, 0.92),
      relative.dy.clamp(0.08, 0.92),
    );
    notifyListeners();
  }

  Future<File?> apply() async {
    if (tabIndex == 0 && model.name.trim().isEmpty) {
      error = 'Type a name for the signature first.';
      notifyListeners();
      return null;
    }
    if (tabIndex == 1 && !model.hasDrawnSignature) {
      error = 'Draw a signature first.';
      notifyListeners();
      return null;
    }
    if (tabIndex == 2 && !model.hasImportedSignature) {
      error = 'Import a signature image first.';
      notifyListeners();
      return null;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      output = await _repository.stampSignature(
        source: source,
        signature: model,
      );
      saving = false;
      notifyListeners();
      return output;
    } catch (e) {
      error = 'Could not stamp the PDF: $e';
      saving = false;
      notifyListeners();
      return null;
    }
  }
}
