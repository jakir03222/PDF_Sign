import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../controllers/signature_controller.dart';
import '../models/signature_model.dart';
import 'saved_pdf_dialog.dart';
import 'theme.dart';
import 'widgets/common_widgets.dart';
import 'widgets/page_placement.dart';

class SignatureView extends StatefulWidget {
  const SignatureView({super.key, required this.controller});

  final SignatureController controller;

  @override
  State<SignatureView> createState() => _SignatureViewState();
}

class _SignatureViewState extends State<SignatureView> {
  late final TextEditingController _name;
  final GlobalKey _drawingKey = GlobalKey();
  final List<List<Offset>> _strokes = [];

  SignatureController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: c.model.name);
  }

  @override
  void dispose() {
    _name.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final file = await c.apply();
    if (!mounted) {
      return;
    }
    if (file == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(c.error ?? 'Could not save the signed PDF.'),
          ),
        );
      return;
    }
    await showSavedPdfDialog(context, path: file.path);
  }

  Future<void> _importSignature() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    c.setImportedSignature(bytes);
  }

  Future<void> _saveDrawing() async {
    if (_strokes.isEmpty) {
      c.setDrawnSignature(Uint8List(0));
      return;
    }
    final boundary = _drawingKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data != null) c.setDrawnSignature(data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Draw Signature'),
      ),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          if (_name.text != c.model.name) {
            _name.value = TextEditingValue(
              text: c.model.name,
              selection: TextSelection.collapsed(offset: c.model.name.length),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    SegmentTabs(
                      labels: const ['Type', 'Draw', 'Import'],
                      index: c.tabIndex,
                      onChanged: c.setTab,
                    ),
                    const SizedBox(height: 16),
                    if (c.tabIndex == 1)
                      _DrawSignaturePanel(
                        drawingKey: _drawingKey,
                        strokes: _strokes,
                        onStart: (point) => setState(() => _strokes.add([point])),
                        onUpdate: (point) => setState(() {
                          if (_strokes.isNotEmpty) _strokes.last.add(point);
                        }),
                        onClear: () => setState(() {
                          _strokes.clear();
                          c.clearDrawnSignature();
                        }),
                        onSave: _saveDrawing,
                      )
                    else if (c.tabIndex == 2)
                      _ImportSignaturePanel(controller: c, onImport: _importSignature)
                    else
                      _TypeTab(controller: c, nameController: _name),
                    if (c.error != null) ...[
                      const SizedBox(height: 12),
                      Text(c.error!, style: const TextStyle(color: AppColors.red)),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: RedDoneButton(
                    label: 'Done',
                    busy: c.saving,
                    onPressed: _done,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({required this.controller, required this.nameController});

  final SignatureController controller;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final model = controller.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NameField(controller: controller, textController: nameController),
        const SizedBox(height: 16),
        const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _PreviewCard(model: model),
        const SizedBox(height: 16),
        const Text('Font', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < SignatureModel.fonts.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == SignatureModel.fonts.length - 1 ? 0 : 6),
                  child: _FontThumb(
                    font: SignatureModel.fonts[i],
                    selected: model.fontIndex == i,
                    onTap: () => controller.setFont(i),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Size', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${model.size.round()} pt', style: const TextStyle(color: AppColors.red)),
          ],
        ),
        Slider(
          min: 20,
          max: 80,
          value: model.size,
          activeColor: AppColors.red,
          onChanged: controller.setSize,
        ),
        const Text('Weight', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            _WeightBox(
              label: 'Aa',
              weight: FontWeight.w300,
              selected: !model.bold,
              onTap: () => controller.setBold(false),
            ),
            const SizedBox(width: 10),
            _WeightBox(
              label: 'Aa',
              weight: FontWeight.w800,
              selected: model.bold,
              onTap: () => controller.setBold(true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Color', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < SignatureModel.colors.length; i++)
              GestureDetector(
                onTap: () => controller.setColor(i),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SignatureModel.colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: model.colorIndex == i ? AppColors.red : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3)],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Placement', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Tap or drag on page 1. Default is bottom-center.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: PagePlacement(
            relative: model.relativePosition,
            onChanged: controller.setPosition,
            child: Text(
              model.name.trim().isEmpty ? 'Your name' : model.name,
              style: TextStyle(
                fontFamily: model.font.family,
                fontSize: (model.size * 0.45).clamp(14, 28),
                fontWeight: model.bold ? FontWeight.w700 : FontWeight.w400,
                color: model.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.controller, required this.textController});

  final SignatureController controller;
  final TextEditingController textController;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.textController,
      focusNode: _focus,
      onChanged: widget.controller.setName,
      decoration: InputDecoration(
        hintText: 'Type your name',
        filled: true,
        fillColor: Colors.white,
        suffixIcon: widget.textController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.textController.clear();
                  widget.controller.clearName();
                },
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDD7D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.model});

  final SignatureModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Text(
        model.name.trim().isEmpty ? 'Your name' : model.name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: model.font.family,
          fontSize: model.size,
          fontWeight: model.bold ? FontWeight.w700 : FontWeight.w400,
          color: model.name.trim().isEmpty ? Colors.grey : model.color,
        ),
      ),
    );
  }
}

class _FontThumb extends StatelessWidget {
  const _FontThumb({required this.font, required this.selected, required this.onTap});

  final SignatureFont font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.red : const Color(0xFFDDD7D1), width: selected ? 2 : 1),
        ),
        child: Text(
          'Aa',
          style: TextStyle(fontFamily: font.family, fontSize: 22, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _WeightBox extends StatelessWidget {
  const _WeightBox({
    required this.label,
    required this.weight,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FontWeight weight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.red : const Color(0xFFDDD7D1), width: selected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 22, fontWeight: weight)),
      ),
    );
  }
}

class _DrawSignaturePanel extends StatelessWidget {
  const _DrawSignaturePanel({
    required this.drawingKey,
    required this.strokes,
    required this.onStart,
    required this.onUpdate,
    required this.onClear,
    required this.onSave,
  });

  final GlobalKey drawingKey;
  final List<List<Offset>> strokes;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onClear;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Draw your signature', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Use your finger or stylus in the signing area.', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        RepaintBoundary(
          key: drawingKey,
          child: GestureDetector(
            onPanStart: (details) => onStart(details.localPosition),
            onPanUpdate: (details) => onUpdate(details.localPosition),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.white,
              child: CustomPaint(painter: _SignaturePainter(strokes)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(onPressed: onClear, icon: const Icon(Icons.delete_outline), label: const Text('Clear')),
            const SizedBox(width: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: onSave,
              icon: const Icon(Icons.check),
              label: const Text('Use signature'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()..color = const Color(0xFFE6E1DC)..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, border);
    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      for (var i = 1; i < stroke.length; i++) {
        canvas.drawLine(stroke[i - 1], stroke[i], ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _ImportSignaturePanel extends StatelessWidget {
  const _ImportSignaturePanel({required this.controller, required this.onImport});

  final SignatureController controller;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final bytes = controller.model.importedSignature;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Import a signature image', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Choose a PNG or JPG signature from your device.', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        InkWell(
          onTap: onImport,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 220,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6E1DC)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: bytes == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined, color: AppColors.red, size: 34),
                      SizedBox(height: 8),
                      Text('Tap to choose an image'),
                    ],
                  )
                : Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
        if (bytes != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.clearImportedSignature,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ),
      ],
    );
  }
}
