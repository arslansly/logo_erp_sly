import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'masraf_model.dart';
import 'masraf_receipt_image.dart';
import 'masraf_service.dart';

// Saha satışçısı için masraf (gider) fişi giriş ekranı. Fiş fotoğrafını
// telefonun kamerasıyla çekip yükler; kayıt patron onayına düşer.
class MasrafGirisScreen extends StatefulWidget {
  // Liste ekranından düzenleme için mevcut masraf verilir.
  final MasrafModel? duzenlenecek;

  const MasrafGirisScreen({super.key, this.duzenlenecek});

  @override
  State<MasrafGirisScreen> createState() => _MasrafGirisScreenState();
}

class _MasrafGirisScreenState extends State<MasrafGirisScreen> {
  MasrafKategori _kategori = MasrafKategori.benzin;
  DateTime _date = DateTime.now();
  int? _editId; // düzenlenen masrafın id'si (null = yeni)
  bool _editHasReceipt = false; // düzenlemede sunucudaki mevcut fiş

  final _amountController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _docCodeController = TextEditingController();
  final _picker = ImagePicker();

  File? _foto; // yeni çekilen/seçilen fiş fotoğrafı
  bool _kaydediliyor = false;

  double get _tutar =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  @override
  void initState() {
    super.initState();
    final d = widget.duzenlenecek;
    if (d != null) {
      _editId = d.id;
      _editHasReceipt = d.hasReceipt;
      _kategori = d.kategori;
      _date = d.date;
      _amountController.text = d.amount == 0 ? '' : d.amount.toString();
      _aciklamaController.text = d.aciklama ?? '';
      _docCodeController.text = d.docCode ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _aciklamaController.dispose();
    _docCodeController.dispose();
    super.dispose();
  }

  Future<void> _fotoCek(ImageSource kaynak) async {
    try {
      final x = await _picker.pickImage(
        source: kaynak,
        // Yükleme öncesi sıkıştırma — SQL/blob şişmesini önler.
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (x != null && mounted) {
        setState(() => _foto = File(x.path));
      }
    } catch (e) {
      if (mounted) _snack('Fotoğraf alınamadı: $e', AppColors.negative);
    }
  }

  // Kamera / galeri seçimi için alt sayfa.
  Future<void> _fotoKaynakSec() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.primary),
              title: Text('Kamera ile çek', style: AppTypography.body),
              onTap: () {
                Navigator.pop(ctx);
                _fotoCek(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: Text('Galeriden seç', style: AppTypography.body),
              onTap: () {
                Navigator.pop(ctx);
                _fotoCek(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null && mounted) {
      setState(() => _date = secilen);
    }
  }

  String? _dogrula() {
    if (_tutar <= 0) return 'Tutar sıfırdan büyük olmalı';
    // Yeni kayıtta fiş fotoğrafı zorunlu (masrafın amacı budur).
    if (_editId == null && _foto == null) {
      return 'Lütfen fiş fotoğrafı çekin';
    }
    return null;
  }

  Future<void> _kaydet() async {
    final hata = _dogrula();
    if (hata != null) {
      _snack(hata, AppColors.negative);
      return;
    }

    final masraf = MasrafModel(
      category: _kategori.api,
      date: _date,
      amount: _tutar,
      docCode: _docCodeController.text.trim().isEmpty
          ? null
          : _docCodeController.text.trim(),
      aciklama: _aciklamaController.text.trim().isEmpty
          ? null
          : _aciklamaController.text.trim(),
    );

    setState(() => _kaydediliyor = true);
    try {
      if (_editId != null) {
        await masrafService.updateMasraf(_editId!, masraf, foto: _foto);
      } else {
        await masrafService.createMasraf(masraf, foto: _foto);
      }
      if (!mounted) return;
      _snack(
        _editId != null
            ? 'Masraf güncellendi (onaya gönderildi)'
            : 'Masraf onaya gönderildi',
        AppColors.positive,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      _snack(e.toString(), AppColors.negative);
    }
  }

  void _snack(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        title: Text(_editId != null ? 'Masraf Düzenle' : 'Masraf Fişi'),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
        children: [
          _FotoKarti(
            foto: _foto,
            editId: _editId,
            editHasReceipt: _editHasReceipt,
            onCek: _fotoKaynakSec,
          ),
          const SizedBox(height: AppSpacing.md),
          _KategoriSecici(
            secili: _kategori,
            onSec: (k) => setState(() => _kategori = k),
          ),
          const SizedBox(height: AppSpacing.md),
          _TutarKarti(controller: _amountController),
          const SizedBox(height: AppSpacing.md),
          _TarihBelgeSatiri(
            date: _date,
            onTarih: _tarihSec,
            docCode: _docCodeController,
          ),
          const SizedBox(height: AppSpacing.md),
          _AlanKutusu(
            etiket: 'Açıklama',
            child: TextField(
              controller: _aciklamaController,
              maxLines: 2,
              style: AppTypography.body,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'İsteğe bağlı not',
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _KaydetBari(
        kaydediliyor: _kaydediliyor,
        onKaydet: _kaydet,
      ),
    );
  }
}

// ─── Fiş fotoğrafı kartı ────────────────────────────────────────────────────
class _FotoKarti extends StatelessWidget {
  final File? foto;
  final int? editId;
  final bool editHasReceipt;
  final VoidCallback onCek;

  const _FotoKarti({
    required this.foto,
    required this.editId,
    required this.editHasReceipt,
    required this.onCek,
  });

  @override
  Widget build(BuildContext context) {
    // Yeni çekilen foto önizlemesi
    if (foto != null) {
      return _cerceve(
        context,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(foto!,
              height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        etiket: 'Fişi tekrar çek',
      );
    }
    // Düzenlemede sunucudaki mevcut fiş
    if (editId != null && editHasReceipt) {
      return _cerceve(
        context,
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: MasrafReceiptImage(
            masrafId: editId!,
            size: 200,
            borderRadius: 14,
            enablePreview: false,
          ),
        ),
        etiket: 'Fişi değiştir',
      );
    }
    // Boş — çekmeye davet
    return GestureDetector(
      onTap: onCek,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add_a_photo_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Fiş Fotoğrafı Çek',
                style: AppTypography.h3.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.xs),
            Text('Benzin/otopark fişini hemen kaydet',
                style: AppTypography.caption.copyWith(color: AppColors.slate500)),
          ],
        ),
      ),
    );
  }

  Widget _cerceve(BuildContext context,
      {required Widget child, required String etiket}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onCek,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(etiket),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ─── Kategori seçici (wrap chip) ────────────────────────────────────────────
class _KategoriSecici extends StatelessWidget {
  final MasrafKategori secili;
  final ValueChanged<MasrafKategori> onSec;
  const _KategoriSecici({required this.secili, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return _AlanKutusu(
      etiket: 'Masraf Türü',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: MasrafKategori.values.map((k) {
            final aktif = k == secili;
            return GestureDetector(
              onTap: () => onSec(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: aktif
                      ? k.renk.withValues(alpha: 0.14)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: aktif ? k.renk : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(k.ikon,
                        size: 17,
                        color: aktif ? k.renk : AppColors.slate500),
                    const SizedBox(width: 6),
                    Text(k.adi,
                        style: AppTypography.bodySmall.copyWith(
                          color: aktif ? k.renk : AppColors.slate600,
                          fontWeight:
                              aktif ? FontWeight.w700 : FontWeight.w500,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Tutar kartı ────────────────────────────────────────────────────────────
class _TutarKarti extends StatelessWidget {
  final TextEditingController controller;
  const _TutarKarti({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.negative.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Harcanan Tutar',
              style: AppTypography.caption.copyWith(color: AppColors.negative)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: false,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: AppTypography.currency.copyWith(color: AppColors.negative),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0,00',
                    isCollapsed: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('₺',
                  style: AppTypography.h2.copyWith(color: AppColors.negative)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tarih + belge no satırı ────────────────────────────────────────────────
class _TarihBelgeSatiri extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTarih;
  final TextEditingController docCode;
  const _TarihBelgeSatiri({
    required this.date,
    required this.onTarih,
    required this.docCode,
  });

  String get _tarihStr =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _AlanKutusu(
            etiket: 'Tarih',
            onTap: onTarih,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.slate400),
                const SizedBox(width: AppSpacing.sm),
                Text(_tarihStr, style: AppTypography.body),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AlanKutusu(
            etiket: 'Fiş No',
            child: TextField(
              controller: docCode,
              style: AppTypography.body,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Opsiyonel',
                isCollapsed: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Genel alan kutusu ──────────────────────────────────────────────────────
class _AlanKutusu extends StatelessWidget {
  final String etiket;
  final Widget child;
  final VoidCallback? onTap;
  const _AlanKutusu({required this.etiket, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final kutu = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(etiket,
              style: AppTypography.caption.copyWith(color: AppColors.slate500)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
    if (onTap == null) return kutu;
    return GestureDetector(onTap: onTap, child: kutu);
  }
}

// ─── Kaydet barı ────────────────────────────────────────────────────────────
class _KaydetBari extends StatelessWidget {
  final bool kaydediliyor;
  final VoidCallback onKaydet;
  const _KaydetBari({required this.kaydediliyor, required this.onKaydet});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: kaydediliyor ? null : onKaydet,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: kaydediliyor
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              kaydediliyor ? 'Kaydediliyor…' : 'Masrafı Kaydet (Onaya Gönder)',
              style: AppTypography.button,
            ),
          ),
        ),
      ),
    );
  }
}
