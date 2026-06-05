import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../fatura/fatura_form_screen.dart';
import 'cari_ekstre_screen.dart';
import 'cari_hareket_model.dart';
import 'cari_model.dart';
import 'cari_service.dart';
import 'cari_vade_model.dart';

class CariDetayScreen extends StatefulWidget {
  final int cariId;
  final Cari? initialCari; // Listeden gelen ön veri (anında gözüksün diye)

  const CariDetayScreen({
    super.key,
    required this.cariId,
    this.initialCari,
  });

  @override
  State<CariDetayScreen> createState() => _CariDetayScreenState();
}

class _CariDetayScreenState extends State<CariDetayScreen> {
  Cari? _cari;
  CariVadeAnalizi? _vade;
  List<CariHareket>? _hareketler;
  bool _isLoading = true;
  String? _error;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _cari = widget.initialCari;
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        cariService.getCariById(widget.cariId),
        cariService.getVadeAnalizi(widget.cariId),
        cariService.getHareketler(widget.cariId),
      ]);
      if (!mounted) return;
      setState(() {
        _cari = results[0] as Cari;
        _vade = results[1] as CariVadeAnalizi;
        _hareketler = (results[2] as List<CariHareket>).take(10).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Aksiyon butonları yardımcıları ───
  Future<void> _callPhone() async {
    if (_cari == null || _cari!.phone.isEmpty) {
      _showSnack('Telefon numarası yok');
      return;
    }
    final phone = _cari!.phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      _showSnack('Telefon uygulaması açılamadı');
    }
  }

  Future<void> _openMap() async {
    if (_cari == null) return;
    final query = [_cari!.title, _cari!.city, _cari!.address]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Harita açılamadı');
    }
  }

  Future<void> _sendSms() async {
    if (_cari == null || _cari!.phone.isEmpty) {
      _showSnack('Telefon numarası yok');
      return;
    }
    final phone = _cari!.phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('sms:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      _showSnack('Mesaj uygulaması açılamadı');
    }
  }

  Future<void> _newFatura() async {
    if (_cari == null) {
      _showSnack('Cari bilgisi yüklenmedi');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaturaFormScreen(onceSecilenCari: _cari),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _cari?.title ?? 'Cari',
          style: AppTypography.h2.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.negativeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.negative, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.negative)),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildHeroCard(),
              if (_cari != null && (_cari!.eFatura || _cari!.eArsiv))
                _buildEInvoiceBadge(),
              if (_vade != null && _vade!.hasVadesiGecen) _buildAgingSection(),
              _buildHareketlerSection(),
              _buildBilgiSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO KART
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeroCard() {
    final balance = _cari?.balance ?? 0;
    final isPositive = balance > 0;
    final isNegative = balance < 0;

    final gradientColors = isPositive
        ? [AppColors.negative, const Color(0xFF991B1B)] // Müşteri borçlu
        : isNegative
        ? [AppColors.positive, const Color(0xFF166534)] // Biz borçluyuz
        : [AppColors.primary, AppColors.violetMid];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cari kodu ve durum
            Row(
              children: [
                Expanded(
                  child: Text(
                    _cari?.code ?? '—',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _hideBalance = !_hideBalance),
                  child: Icon(
                    _hideBalance
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Bakiye etiketi
            Text(
              isPositive
                  ? 'Müşteri size borçlu'
                  : isNegative
                  ? 'Siz borçlusunuz'
                  : 'Hesap denk',
              style: AppTypography.body.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 10),

            // Büyük rakam
            _isLoading
                ? Container(
              width: 200,
              height: 38,
              color: Colors.white.withValues(alpha: 0.15),
            )
                : Text(
              _hideBalance
                  ? '₺ • • • • • •'
                  : Formatters.currency(balance.abs()),
              style: AppTypography.display.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: _hideBalance ? 4 : -0.8,
              ),
            ),

            const SizedBox(height: 18),

            // Aksiyon butonları
            Row(
              children: [
                Expanded(child: _buildActionBtn(Icons.phone_rounded, 'Ara', _callPhone)),
                const SizedBox(width: 8),
                Expanded(child: _buildActionBtn(Icons.location_on_rounded, 'Yol', _openMap)),
                const SizedBox(width: 8),
                Expanded(child: _buildActionBtn(Icons.message_rounded, 'Mesaj', _sendSms)),
                const SizedBox(width: 8),
                Expanded(child: _buildActionBtn(Icons.receipt_long_rounded, 'Fatura', _newFatura)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // e-FATURA / e-ARŞİV ROZETİ
  // ═══════════════════════════════════════════════════════════
  Widget _buildEInvoiceBadge() {
    final c = _cari!;
    final isFatura = c.eFatura;
    final color = isFatura ? AppColors.positive : AppColors.accent;
    final bg = isFatura ? AppColors.positiveBg : AppColors.primary.withValues(alpha: 0.08);
    final label = isFatura ? 'e-Fatura Mükellefi' : 'e-Arşiv Mükellefi';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VADE ANALİZİ - YAŞLANDIRMA ÇUBUĞU
  // ═══════════════════════════════════════════════════════════
  Widget _buildAgingSection() {
    final v = _vade!;
    final total = v.toplamVadesiGecen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.negative.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst başlık
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.negativeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.negative,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vadesi geçen',
                    style: AppTypography.h3.copyWith(fontSize: 14),
                  ),
                ),
                Text(
                  Formatters.currency(total),
                  style: AppTypography.h2.copyWith(
                    fontSize: 18,
                    color: AppColors.negative,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            if (v.enEskiVadeGunFarki != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  'En eski vade: ${v.enEskiVadeGunFarki} gün geride',
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // YAŞLANDIRMA ÇUBUĞU
            _buildAgingBar(v, total),

            const SizedBox(height: 14),

            // Bucket detayları
            _agingRow(
              label: '1–30 gün',
              amount: v.vadesi_0_30,
              color: const Color(0xFFEAB308), // amber
            ),
            _agingRow(
              label: '31–60 gün',
              amount: v.vadesi_31_60,
              color: const Color(0xFFEA580C), // orange
            ),
            _agingRow(
              label: '61–90 gün',
              amount: v.vadesi_61_90,
              color: const Color(0xFFDC2626), // red
            ),
            _agingRow(
              label: '90+ gün',
              amount: v.vadesi_90Plus,
              color: const Color(0xFF991B1B), // dark red
              isLast: true,
              isCritical: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingBar(CariVadeAnalizi v, double total) {
    if (total <= 0) return const SizedBox.shrink();

    final f1 = v.vadesi_0_30 / total;
    final f2 = v.vadesi_31_60 / total;
    final f3 = v.vadesi_61_90 / total;
    final f4 = v.vadesi_90Plus / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 12,
        color: AppColors.slate100,
        child: Row(
          children: [
            if (f1 > 0)
              Expanded(
                flex: (f1 * 1000).round(),
                child: Container(color: const Color(0xFFEAB308)),
              ),
            if (f2 > 0)
              Expanded(
                flex: (f2 * 1000).round(),
                child: Container(color: const Color(0xFFEA580C)),
              ),
            if (f3 > 0)
              Expanded(
                flex: (f3 * 1000).round(),
                child: Container(color: const Color(0xFFDC2626)),
              ),
            if (f4 > 0)
              Expanded(
                flex: (f4 * 1000).round(),
                child: Container(color: const Color(0xFF991B1B)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _agingRow({
    required String label,
    required double amount,
    required Color color,
    bool isLast = false,
    bool isCritical = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.slate700,
                fontWeight: isCritical ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            Formatters.currency(amount),
            style: AppTypography.bodySmall.copyWith(
              fontSize: 13,
              color: amount > 0 ? color : AppColors.slate400,
              fontWeight: amount > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SON HAREKETLER
  // ═══════════════════════════════════════════════════════════
  Widget _buildHareketlerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Text(
                  'Son hareketler',
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
                const Spacer(),
                if (_cari != null)
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CariEkstreScreen(cari: _cari!),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Ekstre',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            ...List.generate(3, (_) => _hareketShimmer())
          else if (_hareketler == null || _hareketler!.isEmpty)
            _buildEmptyHareket()
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: List.generate(_hareketler!.length, (i) {
                  final h = _hareketler![i];
                  final isLast = i == _hareketler!.length - 1;
                  return Column(
                    children: [
                      _buildHareketTile(h),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Container(height: 0.5, color: AppColors.slate200),
                        ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHareketTile(CariHareket h) {
    final isIn = h.isTahsilat;
    final color = isIn ? AppColors.positive : AppColors.negative;
    final bg = isIn ? AppColors.positiveBg : AppColors.negativeBg;
    final icon = isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount = h.netAmount.abs();
    final sign = isIn ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.transactionTypeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  h.description.isNotEmpty
                      ? '${h.description} · ${Formatters.relativeTime(h.date)}'
                      : Formatters.relativeTime(h.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${Formatters.currency(amount)}',
            style: AppTypography.h3.copyWith(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hareketShimmer() {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _buildEmptyHareket() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          'Henüz hareket yok',
          style: AppTypography.bodySmall.copyWith(color: AppColors.slate500),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // İLETİŞİM & BİLGİ
  // ═══════════════════════════════════════════════════════════
  Widget _buildBilgiSection() {
    if (_cari == null) return const SizedBox.shrink();
    final c = _cari!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              'İletişim & bilgi',
              style: AppTypography.h3.copyWith(fontSize: 14),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _infoRow(Icons.tag, 'Cari kodu', c.code),
                if (c.taxNumber.isNotEmpty)
                  _infoRow(Icons.badge_outlined, 'Vergi no', c.taxNumber),
                if (c.phone.isNotEmpty)
                  _infoRow(Icons.phone_outlined, 'Telefon', c.phone),
                if (c.email.isNotEmpty)
                  _infoRow(Icons.email_outlined, 'E-posta', c.email),
                if (c.address.isNotEmpty)
                  _infoRow(Icons.home_outlined, 'Adres', c.address),
                if (c.city.isNotEmpty)
                  _infoRow(Icons.location_city_outlined, 'Şehir', c.city,
                      isLast: c.country.isEmpty),
                if (c.country.isNotEmpty)
                  _infoRow(Icons.public, 'Ülke', c.country, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.slate400),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
              ),
              Expanded(
                child: SelectableText(
                  value,
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Container(height: 0.5, color: AppColors.slate200),
          ),
      ],
    );
  }
}