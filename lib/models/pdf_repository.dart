import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'picked_pdf.dart';
import 'signature_model.dart';
import 'watermark_model.dart';

class PdfRepository {
  Future<File> stampSignature({
    required PickedPdf source,
    required SignatureModel signature,
  }) async {
    final document = PdfDocument(inputBytes: source.bytes);
    try {
      final page = document.pages[0];
      final fontBytes = await rootBundle.load(signature.font.asset);
      final pdfFont = PdfTrueTypeFont(
        fontBytes.buffer.asUint8List(),
        signature.size,
      );
      final brush = PdfSolidBrush(_pdfColor(signature.color));
      final text = signature.name.trim();
      final pageSize = page.size;
      final imageBytes = signature.imageSignature;
      if (imageBytes != null) {
        final image = PdfBitmap(imageBytes);
        final width = pageSize.width * 0.32;
        final height = width * image.height / image.width;
        final x = (signature.relativePosition.dx * pageSize.width) - (width / 2);
        final y = (signature.relativePosition.dy * pageSize.height) - (height / 2);
        page.graphics.drawImage(image, Rect.fromLTWH(x, y, width, height));
      } else {
        final measured = pdfFont.measureString(text);
        final width = measured.width + (signature.bold ? 1.2 : 0);
        final height = measured.height;
        final x = (signature.relativePosition.dx * pageSize.width) - (width / 2);
        final y = (signature.relativePosition.dy * pageSize.height) - (height / 2);
        final bounds = Rect.fromLTWH(x, y, width + 10, height + 8);
        page.graphics.drawString(text, pdfFont, brush: brush, bounds: bounds);
        if (signature.bold) {
          page.graphics.drawString(text, pdfFont, brush: brush, bounds: bounds.translate(0.7, 0));
        }
      }

      return await _save(document, prefix: 'signed', originalName: source.name);
    } finally {
      document.dispose();
    }
  }

  Future<File> stampWatermark({
    required PickedPdf source,
    required WatermarkModel watermark,
  }) async {
    final document = PdfDocument(inputBytes: source.bytes);
    try {
      final pageCount = document.pages.count;
      if (watermark.fromPage < 1 ||
          watermark.fromPage > watermark.toPage ||
          watermark.toPage > pageCount) {
        throw RangeError('Watermark page range is outside the PDF.');
      }
      final indexes = List<int>.generate(
        watermark.toPage - watermark.fromPage + 1,
        (i) => watermark.fromPage - 1 + i,
      );
      final font = _standardFont(watermark);
      final alpha = (watermark.opacity * 255).round().clamp(0, 255);
      final brush = PdfSolidBrush(_pdfColor(watermark.color, alpha));
      final text = watermark.displayText;
      final measured = font.measureString(text);
      final image = watermark.hasImage ? PdfBitmap(watermark.imageBytes!) : null;

      for (final index in indexes) {
        final page = document.pages[index];
        final pageSize = page.size;
        final cx = watermark.relativePosition.dx * pageSize.width;
        final cy = watermark.relativePosition.dy * pageSize.height;
        final layer = page.layers.add(
          name: watermark.layer == WatermarkLayer.overContent
              ? 'Watermark (Over Content)'
              : 'Watermark (Under Content)',
        );

        layer.graphics.save();
        layer.graphics.translateTransform(cx, cy);
        layer.graphics.rotateTransform(watermark.rotation);
        if (image != null) {
          final imageWidth = pageSize.width * 0.34;
          final imageHeight = imageWidth * image.height / image.width;
          layer.graphics.drawImage(
            image,
            Rect.fromLTWH(
              -imageWidth / 2,
              -imageHeight / 2,
              imageWidth,
              imageHeight,
            ),
          );
        } else {
          layer.graphics.drawString(
            text,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(
              -measured.width / 2,
              -measured.height / 2,
              measured.width + 12,
              measured.height + 8,
            ),
          );
        }
        layer.graphics.restore();
      }

      return await _save(document, prefix: 'watermarked', originalName: source.name);
    } finally {
      document.dispose();
    }
  }

  PdfStandardFont _standardFont(WatermarkModel watermark) {
    final family = switch (watermark.family) {
      'Times' => PdfFontFamily.timesRoman,
      'Courier' => PdfFontFamily.courier,
      _ => PdfFontFamily.helvetica,
    };
    final styles = <PdfFontStyle>[];
    if (watermark.style == WatermarkStyle.bold ||
        watermark.style == WatermarkStyle.boldItalic) {
      styles.add(PdfFontStyle.bold);
    }
    if (watermark.style == WatermarkStyle.italic ||
        watermark.style == WatermarkStyle.boldItalic) {
      styles.add(PdfFontStyle.italic);
    }
    if (styles.isEmpty) {
      return PdfStandardFont(family, watermark.size);
    }
    return PdfStandardFont(family, watermark.size, multiStyle: styles);
  }

  PdfColor _pdfColor(Color color, [int? alpha]) {
    return PdfColor(
      (color.r * 255).round().clamp(0, 255),
      (color.g * 255).round().clamp(0, 255),
      (color.b * 255).round().clamp(0, 255),
      alpha ?? (color.a * 255).round().clamp(0, 255),
    );
  }

  Future<File> _save(
    PdfDocument document, {
    required String prefix,
    required String originalName,
  }) async {
    final bytes = await document.save();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safe = originalName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final file = File('${dir.path}/${prefix}_${stamp}_$safe');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
