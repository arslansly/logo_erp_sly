import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'patron_model.dart';
import 'patron_service.dart';

/// Çek/senet listesi — patron paneli drill-down.
/// tip: "tahsil" (müşteri çek/senedi, alacak) | "odeme" (kendi çek/senedimiz, borç).
class CeklerScreen extends StatefulWidget {
  final String tip;
  const CeklerScreen({super.key, required this.tip});

  @override
  State<CeklerScreen> createState() => _CeklerScreenState();
}

class _CeklerScreenState extends State<CeklerScreen> {
  late String _tip;
  late Future<List<CekKayit>> _future;

  @override
  void initState() {
    super.initState();
    _tip = widget.tip;
    _future = patronService.getCekler(_tip);
  }

  void _switchTip(String tip) {
    if (tip == _tip) return;
    setState(() {
      _tip = tip;
      _future = patronService.getCekler(_tip);
    });
  }

  Future<void> _refresh() async {
    setState(() => _future = patronService.getCekler(_tip));
    await _future;
  }

  bool get _isTahsil => _tip != 'odeme';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Çek & senet', style: AppTypography.h1.copyWith(fontSize: 20)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.accent,
              child: FutureBuilder<List<CekKayit>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  if (snap.hasError) return _error(snap.error.toString());
                  final cekler = snap.data ?? [];
                  if (cekler.isEmpty) return _empty();
                  return _content(cekler);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tahsil / Ödeme geçişi
  Widget _buildToggle() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _toggleBtn('Tahsil edilecek', 'tahsil'),
            _toggleBtn('Ödenecek', 'odeme'),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, String tip) {
    final active = _tip == tip || (tip == 'tahsil' && _tip != 'odeme');
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTip(tip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.slate900 : AppColors.slate500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(List<CekKayit> cekler) {
    final toplam = cekler.fold<double>(0, (s, c) => s + c.tutar);
    final renk = _isTahsil ? AppColors.positive : AppColors.negative;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isTahsil ? 'Tahsil edilecek toplam' : 'Ödenecek toplam',
                      style: AppTypography.caption.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(Formatters.currency(toplam),
                      style: AppTypography.h1.copyWith(fontSize: 22, color: renk)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${cekler.length} adet',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final c in cekler) ...[
          _cekCard(c),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _cekCard(CekKayit c) {
    final gecmis = c.vade != null &&
        c.vade!.isBefore(DateTime.now().subtract(const Duration(days: 0)));
    final renk = _isTahsil ? AppColors.positive : AppColors.negative;
    final unvan = c.kesideci.isNotEmpty
        ? c.kesideci
        : (c.banka.isNotEmpty ? c.banka : '${c.tur} #${c.id}');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              c.tur == 'Senet'
                  ? Icons.description_outlined
                  : Icons.payments_outlined,
              color: renk,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unvan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3
                        .copyWith(fontSize: 13, color: AppColors.slate900)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _statChip(c.durum),
                    const SizedBox(width: 6),
                    if (c.vade != null)
                      Text(
                        DateFormat('d MMM yyyy', 'tr_TR').format(c.vade!),
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: gecmis ? AppColors.negative : AppColors.slate500,
                          fontWeight:
                              gecmis ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(Formatters.currency(c.tutar),
              style: AppTypography.h3.copyWith(
                fontSize: 14,
                color: renk,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _statChip(String durum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(durum,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
          )),
    );
  }

  Widget _loading() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => Container(
          height: i == 0 ? 84 : 72,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );

  Widget _error(String e) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: AppColors.slate400),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(e,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.slate600)),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.inbox_rounded,
                      size: 38, color: AppColors.slate400),
                ),
                const SizedBox(height: 16),
                Text(
                    _isTahsil
                        ? 'Tahsil edilecek çek/senet yok'
                        : 'Ödenecek çek/senet yok',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.slate500)),
              ],
            ),
          ),
        ],
      );
}
