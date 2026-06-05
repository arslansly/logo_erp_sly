import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'malzeme_service.dart';

// Malzeme kart resmini LG_XXX_FIRMDOC'tan çeker. Hata olunca fallback ikon gösterir.
// Token cache'i sync olduğundan FutureBuilder gerekmez — liste hızlı render olur.
class MalzemeImage extends StatelessWidget {
  final int malzemeId;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackBg;
  final Color? fallbackFg;
  // true ise resme tıklanınca full-screen önizleme açılır.
  final bool enablePreview;

  const MalzemeImage({
    super.key,
    required this.malzemeId,
    this.size = 48,
    this.borderRadius = 12,
    this.fallbackIcon = Icons.inventory_2_rounded,
    this.fallbackBg,
    this.fallbackFg,
    this.enablePreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = fallbackBg ?? AppColors.primary.withValues(alpha: 0.08);
    final fg = fallbackFg ?? AppColors.primary;

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(fallbackIcon, color: fg, size: size * 0.5),
    );

    final token = apiClient.cachedTokenSync;
    if (token == null) return fallback;

    final headers = {'Authorization': 'Bearer $token'};

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: malzemeService.resimUrl(malzemeId),
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
      child: Hero(
        tag: 'malzeme-resim-$malzemeId',
        child: image,
      ),
    );
  }

  void _openPreview(BuildContext context, Map<String, String> headers) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => _MalzemeImagePreview(
          malzemeId: malzemeId,
          imageUrl: malzemeService.resimUrl(malzemeId),
          headers: headers,
        ),
      ),
    );
  }
}

class _MalzemeImagePreview extends StatelessWidget {
  final int malzemeId;
  final String imageUrl;
  final Map<String, String> headers;

  const _MalzemeImagePreview({
    required this.malzemeId,
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
                  tag: 'malzeme-resim-$malzemeId',
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      httpHeaders: headers,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white70),
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
