import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../controllers/watermark_controller.dart';
import '../models/watermark_model.dart';
import 'saved_pdf_dialog.dart';
import 'theme.dart';
import 'widgets/common_widgets.dart';
import 'widgets/page_placement.dart';

class WatermarkView extends StatefulWidget {
  const WatermarkView({super.key, required this.controller});

  final WatermarkController controller;

  @override
  State<WatermarkView> createState() => _WatermarkViewState();
}

class _WatermarkViewState extends State<WatermarkView> {
  late final TextEditingController _text;
  late final TextEditingController _size;
  late final TextEditingController _hex;
  late final TextEditingController _fromPage;
  late final TextEditingController _toPage;

  WatermarkController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: c.model.text);
    _size = TextEditingController(text: c.model.size.round().toString());
    _hex = TextEditingController(text: c.model.hex);
    _fromPage = TextEditingController(text: c.model.fromPage.toString());
    _toPage = TextEditingController(text: c.totalPages.toString());
    c.setPageRange(to: c.totalPages);
  }

  @override
  void dispose() {
    _text.dispose();
    _size.dispose();
    _hex.dispose();
    _fromPage.dispose();
    _toPage.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final file = await c.apply();
    if (!mounted || file == null) {
      return;
    }
    await showSavedPdfDialog(context, path: file.path);
  }

  Future<void> _pickColor() async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorDialog(current: c.model.color),
    );
    if (selected == null) {
      return;
    }
    c.setColor(selected);
    _hex.text = c.model.hex;
  }

  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        c.setError('Could not read that image.');
        return;
      }
      c.setImage(bytes: bytes, name: file.name);
    } catch (e) {
      c.setError('Image picker failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('PDF Watermark'),
      ),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          if (_hex.text != c.model.hex) {
            _hex.text = c.model.hex;
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    SegmentTabs(
                      labels: const ['Text', 'Image'],
                      index: c.tabIndex,
                      onChanged: c.setTab,
                    ),
                    const SizedBox(height: 16),
                    if (c.tabIndex == 1)
                      _ImageWatermarkPanel(controller: c, onPick: _pickImage)
                    else
                      _TextFormatCard(
                        controller: c,
                        textController: _text,
                        sizeController: _size,
                        hexController: _hex,
                        onPickColor: _pickColor,
                      ),
                    if (c.tabIndex == 0 || c.tabIndex == 1) ...[
                      const SizedBox(height: 16),
                      _Extras(controller: c, fromPage: _fromPage, toPage: _toPage),
                    ],
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
                    label: 'Apply Watermark',
                    busy: c.saving,
                    onPressed: c.tabIndex == 0 || c.tabIndex == 1 ? _apply : null,
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

class _ImageWatermarkPanel extends StatelessWidget {
  const _ImageWatermarkPanel({required this.controller, required this.onPick});

  final WatermarkController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final image = controller.model.imageBytes;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Image Watermark', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (image == null)
            InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE6E1DC)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.red, size: 32),
                    SizedBox(height: 8),
                    Text('Choose an image'),
                    SizedBox(height: 4),
                    Text('PNG, JPG or other supported image', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.memory(image, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.model.imageName ?? 'Selected image',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onPick,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Change'),
                    ),
                    IconButton(
                      tooltip: 'Remove image',
                      onPressed: controller.clearImage,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TextFormatCard extends StatelessWidget {
  const _TextFormatCard({
    required this.controller,
    required this.textController,
    required this.sizeController,
    required this.hexController,
    required this.onPickColor,
  });

  final WatermarkController controller;
  final TextEditingController textController;
  final TextEditingController sizeController;
  final TextEditingController hexController;
  final VoidCallback onPickColor;

  @override
  Widget build(BuildContext context) {
    final model = controller.model;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Text Format', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: textController,
            onChanged: controller.setText,
            decoration: InputDecoration(
              hintText: 'Watermark',
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.red, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: model.family,
                  decoration: const InputDecoration(labelText: 'Font family'),
                  items: [
                    for (final family in WatermarkModel.families)
                      DropdownMenuItem(value: family, child: Text(family)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.setFamily(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: sizeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final n = double.tryParse(v);
                    if (n != null) {
                      controller.setSize(n);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Size'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<WatermarkStyle>(
            initialValue: model.style,
            decoration: const InputDecoration(labelText: 'Style'),
            items: const [
              DropdownMenuItem(value: WatermarkStyle.regular, child: Text('Regular')),
              DropdownMenuItem(value: WatermarkStyle.italic, child: Text('Italic')),
              DropdownMenuItem(value: WatermarkStyle.bold, child: Text('Bold')),
              DropdownMenuItem(value: WatermarkStyle.boldItalic, child: Text('Bold Italic')),
            ],
            onChanged: (v) {
              if (v != null) {
                controller.setStyle(v);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onPickColor,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: model.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.red, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: hexController,
                  onChanged: controller.setHex,
                  onTap: onPickColor,
                  decoration: const InputDecoration(labelText: 'Hex'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Extras extends StatelessWidget {
  const _Extras({required this.controller, required this.fromPage, required this.toPage});

  final WatermarkController controller;
  final TextEditingController fromPage;
  final TextEditingController toPage;

  @override
  Widget build(BuildContext context) {
    final model = controller.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Opacity', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${(model.opacity * 100).round()}%'),
          ],
        ),
        Slider(
          min: 0,
          max: 1,
          value: model.opacity,
          activeColor: AppColors.red,
          onChanged: controller.setOpacity,
        ),
        Row(
          children: [
            const Text('Rotation', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${model.rotation.round()}°'),
          ],
        ),
        Slider(
          min: -180,
          max: 180,
          value: model.rotation,
          activeColor: AppColors.red,
          onChanged: controller.setRotation,
        ),
        const SizedBox(height: 8),
        const Text('Position', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _AnchorGrid(controller: controller),
        const SizedBox(height: 12),
        DropdownButtonFormField<WatermarkLayer>(
          initialValue: model.layer,
          decoration: const InputDecoration(labelText: 'Layer'),
          items: const [
            DropdownMenuItem(value: WatermarkLayer.overContent, child: Text('Over Content')),
            DropdownMenuItem(value: WatermarkLayer.underContent, child: Text('Under Content')),
          ],
          onChanged: (value) {
            if (value != null) controller.setLayer(value);
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: PagePlacement(
            relative: model.relativePosition,
            onChanged: controller.setPosition,
            child: Opacity(
              opacity: model.opacity,
              child: Transform.rotate(
                angle: model.rotation * 3.14159 / 180,
                  child: model.hasImage
                      ? Image.memory(model.imageBytes!, width: 120, fit: BoxFit.contain)
                      : Text(
                          model.displayText,
                          style: TextStyle(
                            fontSize: model.size,
                            fontWeight: model.fontWeight,
                            fontStyle: model.fontStyle,
                            color: model.color,
                            fontFamily: model.family == 'Times'
                                ? 'serif'
                                : model.family == 'Courier'
                                    ? 'monospace'
                                    : null,
                          ),
                        ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEEC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                model.hasImage
                    ? 'Image watermark'
                    : '${(model.size * model.displayText.length * 0.55).round()} × ${(model.size * 1.25).round()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Page Range', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: fromPage,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'From Page'),
                onChanged: (value) => controller.setPageRange(from: int.tryParse(value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: toPage,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: 'To Page (of ${controller.totalPages})'),
                onChanged: (value) => controller.setPageRange(to: int.tryParse(value)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnchorGrid extends StatelessWidget {
  const _AnchorGrid({required this.controller});

  final WatermarkController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.model.relativePosition;
    return SizedBox(
      width: 156,
      height: 156,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: [
          for (var row = 0; row < 3; row++)
            for (var column = 0; column < 3; column++)
              _AnchorCell(
                selected: (selected.dx - (column + 1) / 4).abs() < 0.1 &&
                    (selected.dy - (row + 1) / 4).abs() < 0.1,
                onTap: () => controller.setPosition(
                  Offset((column + 1) / 4, (row + 1) / 4),
                ),
              ),
        ],
      ),
    );
  }
}

class _AnchorCell extends StatelessWidget {
  const _AnchorCell({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.red.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(color: selected ? AppColors.red : const Color(0xFFE6E1DC)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? AppColors.red : const Color(0xFFBDBDBD),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDialog extends StatelessWidget {
  const _ColorDialog({required this.current});

  final Color current;

  static const swatches = <Color>[
    Color(0xFFE53935),
    Color(0xFF111111),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFFAD1457),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Color picker'),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final color in swatches)
            GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == current ? AppColors.red : Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
