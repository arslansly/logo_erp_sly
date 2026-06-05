import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'belge_pdf.dart';

/// Belge PDF önizleme + paylaş/yazdır ekranı.
/// `printing` paketinin PdfPreview'ı yerleşik paylaş ve yazdır butonları sağlar.
class BelgeOnizlemeScreen extends StatelessWidget {
  final BelgePdfData data;
  const BelgeOnizlemeScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Belge Önizleme'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
      ),
      body: PdfPreview(
        build: (format) => belgePdfOlustur(data),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '${data.dosyaAdi}.pdf',
        loadingWidget: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
      ),
    );
  }
}
