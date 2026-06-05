import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// PDF bytes'ını uygulama içinde görüntüler; paylaş/indir butonları dahildir.
class PdfOnizlemeScreen extends StatelessWidget {
  final String baslik;
  final Future<Uint8List> Function() pdfOlustur;

  const PdfOnizlemeScreen({
    super.key,
    required this.baslik,
    required this.pdfOlustur,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.slate700),
        title: Text(
          baslik,
          style: AppTypography.h2.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PdfPreview(
        build: (_) => pdfOlustur(),
        useActions: true,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: '${baslik.replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ_-]+'), '_')}.pdf',
        loadingWidget: const Center(
          child: CircularProgressIndicator(),
        ),
        initialPageFormat: PdfPageFormat.a4,
        actionBarTheme: PdfActionBarTheme(
          backgroundColor: AppColors.surface,
          iconColor: AppColors.slate700,
          textStyle: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
