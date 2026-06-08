import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../siparis/siparis_detay_screen.dart';
import 'saha_model.dart';
import 'saha_service.dart';
import 'saha_widgets.dart';

/// Açık (sevk bekleyen) siparişlerin tam listesi — saha panelinden açılır.
class AcikSiparislerScreen extends StatefulWidget {
  final int? satisciRef;
  final String satisciAd;

  const AcikSiparislerScreen({
    super.key,
    required this.satisciRef,
    required this.satisciAd,
  });

  @override
  State<AcikSiparislerScreen> createState() => _AcikSiparislerScreenState();
}

class _AcikSiparislerScreenState extends State<AcikSiparislerScreen> {
  List<SahaAcikSiparis>? _list;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await sahaService.getAcikSiparisler(
          satisciRef: widget.satisciRef, limit: 200);
      if (!mounted) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Açık siparişler', style: AppTypography.h2.copyWith(fontSize: 16)),
            Text(widget.satisciAd,
                style: AppTypography.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 48, color: AppColors.slate400),
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.slate600)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_loading) return _skeleton();

    final list = _list ?? const <SahaAcikSiparis>[];
    if (list.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: SahaEmptyState(
              icon: Icons.check_circle_outline_rounded,
              mesaj: 'Sevk bekleyen sipariş yok',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AcikSiparisTile(
          siparis: list[i],
          showSatisci: widget.satisciRef == null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SiparisDetayScreen(id: list[i].id)),
          ),
        ),
      ),
    );
  }

  Widget _skeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.slate200,
      highlightColor: AppColors.slate100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
