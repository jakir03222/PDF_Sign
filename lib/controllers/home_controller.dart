import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/picked_pdf.dart';

class HomeController extends ChangeNotifier {
  PickedPdf? pdf;
  String? error;
  bool picking = false;

  Future<bool> pickPdf() async {
    picking = true;
    error = null;
    notifyListeners();
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null) {
        picking = false;
        notifyListeners();
        return false;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        error = 'Could not read that PDF. Try another file.';
        picking = false;
        notifyListeners();
        return false;
      }
      pdf = PickedPdf(name: file.name, bytes: bytes);
      picking = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'PDF picker failed: $e';
      picking = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
