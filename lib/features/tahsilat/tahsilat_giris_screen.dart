import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../cari/cari_model.dart';
import '../cari/cari_list_screen.dart';
import 'tahsilat_model.dart';
import 'tahsilat_taslak_service.dart';

// Saha satışçısı için tahsilat / ödeme fişi giriş ekranı.
// Taslak olarak kaydeder; LOGO'ya toplu aktarım ileride (backend stub).
class TahsilatGirisScreen extends StatefulWidget {
  // Cari listesinden açıldıysa cari kilitli gelir.
  final Cari? onceSecilenCari;
  // Liste ekranından düzenleme için mevcut taslak verilir.
  final TahsilatTaslakModel? duzenlenecek;

  const TahsilatGirisScreen({
    super.key,
    this.onceSecilenCari,
    this.duzenlenecek,
  });

  @override
  State<TahsilatGirisScreen> createState() => _TahsilatGirisScreenState();
}

class _TahsilatGirisScreenState extends State<TahsilatGirisScreen> {
  TahsilatTuru _tur = TahsilatTuru.nakitTahsilat;
  Cari? _selectedCari;
  DateTime _date = DateTime.now();
  int? _editId; // düzenlenen taslağın id'si (null = yeni kayıt)
  Map<String, dynamic>? _editExtra; // düzenlemede ek alan değerleri

  final _amountController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _docCodeController = TextEditingController();
  // Şema-driven ek alanların controller'ları (key → controller).
  final Map<String, TextEditingController> _ekControllers = {};

  TahsilatSema _sema = TahsilatSema.baseline();
  bool _semaYukleniyor = true;
  bool _kaydediliyor = false;

  double get _tutar =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  @override
  void initState() {
    super.initState();
    final d = widget.duzenlenecek;
    if (d != null) {
      // Düzenleme — mevcut taslağın alanlarını doldur.
      _editId = d.id;
      _editExtra = d.extraFields;
      _tur = d.tur;
      _date = d.date;
      _selectedCari = Cari(
        id: d.clientRef,
        code: d.clientCode,
        title: d.clientTitle,
        balance: 0,
        city: '',
        phone: '',
      );
      _amountController.text = d.amount == 0 ? '' : d.amount.toString();
      _aciklamaController.text = d.aciklama ?? '';
      _docCodeController.text = d.docCode ?? '';
    } else {
      _selectedCari = widget.onceSecilenCari;
    }
    _semaYukle();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _aciklamaController.dispose();
    _docCodeController.dispose();
    for (final c in _ekControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Seçili türe göre firmaya özel ek alanları Logo'dan öğren.
  Future<void> _semaYukle() async {
    setState(() => _semaYukleniyor = true);
    final sema = await tahsilatTaslakService.getSchema(_tur.trCode);
    if (!mounted) return;
    // Yeni alanlar için controller hazırla, default değerleri yerleştir.
    for (final alan in sema.ekAlanlar) {
      final c = _ekControllers.putIfAbsent(
          alan.key, () => TextEditingController());
      // Düzenlemedeki değer önceliklidir, yoksa şema varsayılanı.
      final mevcut = _editExtra?[alan.key]?.toString();
      if (mevcut != null && mevcut.isNotEmpty) {
        c.text = mevcut;
      } else if (alan.varsayilan != null && c.text.isEmpty) {
        c.text = alan.varsayilan!;
      }
    }
    setState(() {
      _sema = sema;
      _semaYukleniyor = false;
    });
  }

  void _turDegistir(TahsilatTuru tur) {
    if (tur == _tur) return;
    setState(() => _tur = tur);
    _semaYukle(); // ek alanlar türe göre değişebilir
  }

  Future<void> _cariSec() async {
    final result = await Navigator.push<Cari>(
      context,
      MaterialPageRoute(
        builder: (_) => const CariListScreen(selectionMode: true),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedCari = result);
    }
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
    if (_selectedCari == null) return 'Lütfen bir cari seçin';
    if (_tutar <= 0) return 'Tutar sıfırdan büyük olmalı';
    for (final alan in _sema.ekAlanlar) {
      if (alan.zorunlu && (_ekControllers[alan.key]?.text.trim().isEmpty ?? true)) {
        return '${alan.label} alanı zorunlu';
      }
    }
    return null;
  }

  Future<void> _kaydet() async {
    final hata = _dogrula();
    if (hata != null) {
      _snack(hata, AppColors.negative);
      return;
    }

    final ekFields = <String, dynamic>{};
    for (final alan in _sema.ekAlanlar) {
      final v = _ekControllers[alan.key]?.text.trim() ?? '';
      if (v.isNotEmpty) ekFields[alan.key] = v;
    }

    final draft = TahsilatTaslakModel(
      trCode: _tur.trCode,
      date: _date,
      clientRef: _selectedCari!.id,
      clientCode: _selectedCari!.code,
      clientTitle: _selectedCari!.title,
      amount: _tutar,
      docCode: _docCodeController.text.trim().isEmpty
          ? null
          : _docCodeController.text.trim(),
      aciklama: _aciklamaController.text.trim().isEmpty
          ? null
          : _aciklamaController.text.trim(),
      extraFields: ekFields.isEmpty ? null : ekFields,
    );

    setState(() => _kaydediliyor = true);
    try {
      if (_editId != null) {
        await tahsilatTaslakService.updateTaslak(_editId!, draft);
      } else {
        await tahsilatTaslakService.createTaslak(draft);
      }
      if (!mounted) return;
      _snack(
        _editId != null
            ? '${_tur.adi} güncellendi (onaya gönderildi)'
            : '${_tur.adi} onaya gönderildi',
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
        title: Text(_editId != null ? 'Tahsilat Düzenle' : 'Tahsilat Fişi'),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
        children: [
          _TurSecici(secili: _tur, onSec: _turDegistir),
          const SizedBox(height: AppSpacing.md),
          _TutarKarti(controller: _amountController, tur: _tur),
          const SizedBox(height: AppSpacing.md),
          _CariSecici(
            selectedCari: _selectedCari,
            kilitli: widget.onceSecilenCari != null,
            onSelect: _cariSec,
          ),
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
          // Şema-driven ek alanlar (firmaya özel zorunluluklar Logo'dan gelir)
          if (_semaYukleniyor) ...[
            const SizedBox(height: AppSpacing.md),
            const _EkAlanIskelet(),
          ] else
            ..._sema.ekAlanlar.map((alan) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _EkAlan(
                    alan: alan,
                    controller: _ekControllers[alan.key]!,
                  ),
                )),
        ],
      ),
      bottomNavigationBar: _KaydetBari(
        tur: _tur,
        kaydediliyor: _kaydediliyor,
        onKaydet: _kaydet,
      ),
    );
  }
}

// ─── Tür seçici (segment) ───────────────────────────────────────────────────
class _TurSecici extends StatelessWidget {
  final TahsilatTuru secili;
  final ValueChanged<TahsilatTuru> onSec;
  const _TurSecici({required this.secili, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: TahsilatTuru.values.map((t) {
          final aktif = t == secili;
          final renk = t.isOdeme ? AppColors.negative : AppColors.positive;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSec(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: aktif ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: aktif
                      ? [
                          BoxShadow(
                            color: AppColors.slate900.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(t.ikon,
                        size: 20,
                        color: aktif ? renk : AppColors.slate400),
                    const SizedBox(height: 4),
                    Text(
                      t.adi,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: aktif ? AppColors.slate900 : AppColors.slate500,
                        fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tutar kartı ────────────────────────────────────────────────────────────
class _TutarKarti extends StatelessWidget {
  final TextEditingController controller;
  final TahsilatTuru tur;
  const _TutarKarti({required this.controller, required this.tur});

  @override
  Widget build(BuildContext context) {
    final renk = tur.isOdeme ? AppColors.negative : AppColors.positive;
    final bg = tur.isOdeme ? AppColors.negativeBg : AppColors.positiveBg;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tur.isOdeme ? 'Ödenecek Tutar' : 'Tahsil Edilecek Tutar',
            style: AppTypography.caption.copyWith(color: renk),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: AppTypography.currency.copyWith(color: renk),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0,00',
                    isCollapsed: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('₺', style: AppTypography.h2.copyWith(color: renk)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Cari seçici ────────────────────────────────────────────────────────────
class _CariSecici extends StatelessWidget {
  final Cari? selectedCari;
  final bool kilitli;
  final VoidCallback onSelect;
  const _CariSecici({
    required this.selectedCari,
    required this.kilitli,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: kilitli ? null : onSelect,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedCari == null
                  ? AppColors.slate300
                  : AppColors.slate200,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_rounded, color: AppColors.slate500),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cari',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.slate500)),
                    const SizedBox(height: 2),
                    Text(
                      selectedCari?.title ?? 'Cari seçin',
                      style: AppTypography.body.copyWith(
                        color: selectedCari == null
                            ? AppColors.slate400
                            : AppColors.slate900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (selectedCari != null)
                      Text(selectedCari!.code, style: AppTypography.caption),
                  ],
                ),
              ),
              if (kilitli)
                const Icon(Icons.lock_outline_rounded,
                    size: 18, color: AppColors.slate400)
              else
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.slate400),
            ],
          ),
        ),
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
            etiket: 'Belge No',
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

// ─── Şema-driven ek alan ────────────────────────────────────────────────────
class _EkAlan extends StatelessWidget {
  final TahsilatAlan alan;
  final TextEditingController controller;
  const _EkAlan({required this.alan, required this.controller});

  @override
  Widget build(BuildContext context) {
    final etiket = alan.zorunlu ? '${alan.label} *' : alan.label;
    if (alan.tip == TahsilatAlanTipi.secim && alan.secenekler.isNotEmpty) {
      return _AlanKutusu(
        etiket: etiket,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            isDense: true,
            value: controller.text.isEmpty ? null : controller.text,
            hint: Text('Seçin', style: AppTypography.body),
            items: alan.secenekler
                .map((s) => DropdownMenuItem(
                    value: s.deger,
                    child: Text(s.etiket, style: AppTypography.body)))
                .toList(),
            onChanged: (v) => controller.text = v ?? '',
          ),
        ),
      );
    }
    return _AlanKutusu(
      etiket: etiket,
      child: TextField(
        controller: controller,
        keyboardType: alan.tip == TahsilatAlanTipi.sayi
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: AppTypography.body,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}

// Şema yüklenirken iskelet (skeleton) — şema-driven alanların yerini tutar.
class _EkAlanIskelet extends StatelessWidget {
  const _EkAlanIskelet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text('Alanlar yükleniyor…',
          style: AppTypography.caption.copyWith(color: AppColors.slate400)),
    );
  }
}

// ─── Kaydet barı ────────────────────────────────────────────────────────────
class _KaydetBari extends StatelessWidget {
  final TahsilatTuru tur;
  final bool kaydediliyor;
  final VoidCallback onKaydet;
  const _KaydetBari({
    required this.tur,
    required this.kaydediliyor,
    required this.onKaydet,
  });

  @override
  Widget build(BuildContext context) {
    final renk = tur.isOdeme ? AppColors.negative : AppColors.positive;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: kaydediliyor ? null : onKaydet,
            style: FilledButton.styleFrom(
              backgroundColor: renk,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
              kaydediliyor ? 'Kaydediliyor…' : 'Taslağı Kaydet (Onaya Gönder)',
              style: AppTypography.button,
            ),
          ),
        ),
      ),
    );
  }
}
