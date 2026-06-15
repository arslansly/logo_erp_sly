import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'masraf_service.dart';

// Masraf fişi fotoğrafını /api/ExpenseDraft/{id}/receipt'ten çeker (JWT header'lı).
// MalzemeImage deseni: token sync cache'ten okunur, tıklanınca full-screen önizleme.
class MasrafReceiptImage extends StatelessWidget {
  final int masrafId;
  final double size;
  final double borderRadius;
  // true ise resme tıklanınca tam ekran önizleme açılır.
  final bool enablePreview;

  const MasrafReceiptImage({
    super.key,
    required this.masrafId,
    this.size = 56,
    this.borderRadius = 12,
    this.enablePreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.receipt_long_rounded,
          color: AppColors.slate400, size: 24),
    );

    final token = apiClient.cachedTokenSync;
    if (token == null) return fallback;

    final headers = {'Authorization': 'Bearer $token'};

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: masrafService.receiptUrl(masrafId),
        httpHeaders: headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );

    if (!enablePreview) return image;

    return GestureDetector(
      onTap: () => _openPreview(context, headers),
      child: Hero(tag: 'masraf-fis-$masrafId', child: image),
    );
  }

  void _openPreview(BuildContext context, Map<String, String> headers) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => _MasrafReceiptPreview(
          masrafId: masrafId,
          imageUrl: masrafService.receiptUrl(masrafId),
          headers: headers,
        ),
      ),
    );
  }
}

class _MasrafReceiptPreview extends StatelessWidget {
  final int masrafId;
  final String imageUrl;
  final Map<String, String> headers;

  const _MasrafReceiptPreview({
    required this.masrafId,
    required this.imageUrl,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Hero(
                  tag: 'masraf-fis-$masrafId',
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      httpHeaders: headers,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white70),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 64),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
