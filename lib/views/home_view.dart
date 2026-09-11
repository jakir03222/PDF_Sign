import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../controllers/signature_controller.dart';
import '../controllers/watermark_controller.dart';
import 'signature_view.dart';
import 'theme.dart';
import 'watermark_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.controller});

  final HomeController controller;

  Future<void> _goSignature(BuildContext context) async {
    final ok = controller.pdf != null || await controller.pickPdf();
    if (!ok || !context.mounted || controller.pdf == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignatureView(
          controller: SignatureController(source: controller.pdf!),
        ),
      ),
    );
  }

  Future<void> _goWatermark(BuildContext context) async {
    final ok = controller.pdf != null || await controller.pickPdf();
    if (!ok || !context.mounted || controller.pdf == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WatermarkView(
          controller: WatermarkController(source: controller.pdf!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Sign & Watermark')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF WORKSPACE',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Make every page\nfeel finished.',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign documents and place precise text watermarks, then save a clean PDF copy.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                ),
                const SizedBox(height: 24),
                _PdfCard(controller: controller, onPick: controller.pickPdf),
                if (controller.error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: controller.error!),
                ],
                const SizedBox(height: 26),
                const Text(
                  'Choose an action',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.draw_outlined,
                  title: 'Signature',
                  subtitle: 'Type your name and place it on page 1',
                  accent: AppColors.red,
                  onTap: () => _goSignature(context),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.branding_watermark_outlined,
                  title: 'Watermark',
                  subtitle: 'Style text and apply it to selected pages',
                  accent: const Color(0xFF1769AA),
                  onTap: () => _goWatermark(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.controller, required this.onPick});

  final HomeController controller;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final pdf = controller.pdf;
    return Material(
      color: pdf == null ? const Color(0xFF2D2522) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: controller.picking ? null : onPick,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: pdf == null ? const Color(0xFFE85B53) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: pdf == null ? Colors.white : AppColors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf?.name ?? 'Select a PDF to begin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pdf == null ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pdf == null
                          ? 'Choose a real document from your device'
                          : '${_formatBytes(pdf.bytes.length)}  /  tap to change',
                      style: TextStyle(
                        color: pdf == null ? const Color(0xFFD6C8C2) : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.picking)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  pdf == null ? Icons.arrow_forward_rounded : Icons.edit_outlined,
                  color: pdf == null ? Colors.white : AppColors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.redDark, fontSize: 12)),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
