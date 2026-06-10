import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/pdf/belge_pdf.dart';
import '../../core/pdf/belge_onizleme_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/onay_rozeti.dart';
import '../../core/theme/app_typography.dart';
import '../cari/cari_list_screen.dart';
import '../cari/cari_model.dart';
import '../fatura/currency_model.dart';
import '../fatura/lookup_service.dart';
import '../malzeme/malzeme_list_screen.dart';
import '../malzeme/malzeme_model.dart';
import '../malzeme/malzeme_service.dart';
import 'siparis_model.dart';
import 'siparis_taslak_service.dart';
import '../ai/ai_model.dart';

/// Sipariş ekleme/düzenleme ekranı.
/// - `taslakId == null` → yeni sipariş (önce tür seçimi)
/// - `taslakId != null` → mevcut taslağı düzenle
/// - `onceSecilenCari` dolu → cari önceden set edilir (cari detayından "Sipariş Oluştur")
/// Yeni taslak LOGO ORFICHE.STATUS = 1 (Öneri) ile kaydedilir (backend sabit).
class SiparisFormScreen extends StatefulWidget {
  final int? taslakId;
  final Cari? onceSecilenCari;
  // Yapay zeka asistanından gelen ön-dolu satırlar ve opsiyonel vade (termin).
  final List<AiLineSeed>? onceSecilenSatirlar;
  final DateTime? vade;
  // AI'dan gelen sipariş türü (ORFICHE TRCODE: 1=Satış, 2=Satınalma). Verilmezse Satış.
  final int? onceSecilenTrCode;
  const SiparisFormScreen({
    super.key,
    this.taslakId,
    this.onceSecilenCari,
    this.onceSecilenSatirlar,
    this.vade,
    this.onceSecilenTrCode,
  });

  @override
  State<SiparisFormScreen> createState() => _SiparisFormScreenState();
}

class _SiparisFormScreenState extends State<SiparisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ficheNoController = TextEditingController();
  final _docCodeController = TextEditingController();
  final _genExp1Controller = TextEditingController();

  SiparisTuru? _tur;
  DateTime _date = DateTime.now();
  DateTime? _terminDate; // fiş bazlı varsayılan termin
  Cari? _selectedCari;
  final List<_LineDraft> _lines = [];

  // KDV dahil mi? Toggle açıkken birim fiyatlar KDV dahil olarak girilir,
  // backend'e gönderilirken her zaman KDV hariç'e çevrilir.
  bool _kdvDahil = false;

  // Döviz
  int _currencyType = 0; // 0 = TL
  final TextEditingController _exchangeRateController =
      TextEditingController(text: '1');
  List<CurrencyModel> _currencies = [CurrencyModel.tl];
  bool _loadingExchangeRate = false;

  // Ek bilgi alanları
  List<LookupItem> _salesmen = [];
  List<LookupItem> _payPlans = [];
  LookupItem? _selectedSalesman;
  LookupItem? _selectedPayDef;
  bool _loadingLookups = true;
  String? _lookupError;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;
  int? _existingDraftId;
  String? _onayDurumu; // düzenlenen taslağın onay durumu
  String? _redGerekce; // reddedildiyse gerekçe

  @override
  void initState() {
    super.initState();
    if (widget.onceSecilenCari != null) {
      _selectedCari = widget.onceSecilenCari;
    }
    // AI'dan satır geldiyse: tür seçimini atla (AI'ın türü, yoksa Satış), vade + satırları doldur.
    if (widget.onceSecilenSatirlar != null &&
        widget.onceSecilenSatirlar!.isNotEmpty) {
      _tur = (widget.onceSecilenTrCode != null
              ? SiparisTuru.fromTrCode(widget.onceSecilenTrCode!)
              : null) ??
          SiparisTuru.satis;
      if (widget.vade != null) _terminDate = widget.vade;
      _seedAiLines();
    }
    if (widget.taslakId != null) {
      _loadExistingDraft();
    }
    _loadCurrencies();
    _loadLookups();
  }

  // AI tohum satırlarını forma ekler; stok/tanımlı fiyat detayını arka planda doldurur.
  void _seedAiLines() {
    for (final seed in widget.onceSecilenSatirlar!) {
      final l = _LineDraft(
        stockRef: seed.stokRef,
        stockCode: seed.kod,
        stockName: seed.ad,
        uomCode: seed.birim,
        amount: seed.miktar == 0 ? '' : _fmtPlain(seed.miktar),
        price: (seed.fiyat != null && seed.fiyat! > 0)
            ? _fmtPlain(seed.fiyat!)
            : '',
      );
      _lines.add(l);
      _hydrateSeedLine(l);
    }
  }

  Future<void> _hydrateSeedLine(_LineDraft l) async {
    if (l.stockRef == null) return;
    try {
      final detay = await malzemeService.getMalzemeDetay(l.stockRef!);
      if (!mounted) return;
      setState(() {
        // Fiyat boşsa türe göre tanımlı fiyatı koy (kullanıcı değiştirebilir).
        if (l.priceC.text.trim().isEmpty) {
          final isSatis = _tur?.kategori == 'Satış';
          final tanimli = isSatis ? detay.satisFiyati : detay.satinalmaFiyati;
          if (tanimli > 0) l.priceC.text = _fmtPlain(tanimli);
        }
      });
    } catch (_) {
      // Detay alınamazsa sessiz geç — kullanıcı manuel girer
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      final list = await lookupService.getCurrencies();
      if (!mounted) return;
      setState(() {
        _currencies = [CurrencyModel.tl, ...list];
      });
    } catch (_) {
      // Lookup başarısız → sadece TL ile devam
    }
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });
    try {
      final results = await Future.wait([
        lookupService.getSalesmen(),
        lookupService.getPayPlans(),
      ]);
      if (!mounted) return;
      setState(() {
        _salesmen = results[0];
        _payPlans = results[1];
        _selectedSalesman = _findById(_salesmen, _selectedSalesman?.id);
        _selectedPayDef = _findById(_payPlans, _selectedPayDef?.id);
        _loadingLookups = false;
      });
    } catch (e) {
      debugPrint('[siparis_form] Lookup yüklenemedi: $e');
      if (!mounted) return;
      setState(() {
        _lookupError = e.toString();
        _loadingLookups = false;
      });
    }
  }

  LookupItem? _findById(List<LookupItem> list, int? id) {
    if (id == null) return null;
    for (final i in list) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _onCurrencyChanged(int? newType) async {
    if (newType == null) return;
    setState(() {
      _currencyType = newType;
      if (newType == 0) {
        _exchangeRateController.text = '1';
      }
    });
    if (newType == 0) return;

    setState(() => _loadingExchangeRate = true);
    try {
      final rate = await lookupService.getExchangeRate(newType);
      if (!mounted) return;
      if (rate.hasData && rate.defaultRate > 0) {
        _exchangeRateController.text = _fmtPlain(rate.defaultRate);
      } else {
        _exchangeRateController.text = '';
      }
    } catch (_) {
      if (!mounted) return;
      _exchangeRateController.text = '';
    } finally {
      if (mounted) setState(() => _loadingExchangeRate = false);
    }
  }

  Future<void> _loadExistingDraft() async {
    setState(() => _isLoading = true);
    try {
      final t = await siparisTaslakService.getTaslakById(widget.taslakId!);
      if (!mounted) return;
      setState(() {
        _existingDraftId = t.id;
        _onayDurumu = t.approvalStatus;
        _redGerekce = t.rejectReason;
        _tur = SiparisTuru.fromTrCode(t.trCode);
        _date = t.date;
        _terminDate = t.dueDate;
        _ficheNoController.text = t.ficheNo ?? '';
        _docCodeController.text = t.docCode ?? '';
        _genExp1Controller.text = t.genExp1 ?? '';
        _currencyType = t.currencyType;
        _exchangeRateController.text = _fmtPlain(t.exchangeRate);
        _selectedSalesman = t.salesmanRef != null
            ? LookupItem(id: t.salesmanRef!, code: '', name: '')
            : null;
        _selectedPayDef = t.payDefRef != null
            ? LookupItem(id: t.payDefRef!, code: '', name: '')
            : null;
        _selectedCari = Cari(
          id: t.clientRef,
          code: t.clientCode,
          title: t.clientTitle,
          balance: 0,
          city: '',
          phone: '',
        );
        _lines.clear();
        for (final l in t.lines) {
          _lines.add(_LineDraft.fromTaslak(l));
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ficheNoController.dispose();
    _docCodeController.dispose();
    _genExp1Controller.dispose();
    _exchangeRateController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Toplam hesap (her zaman KDV hariç tabanlı) ──
  double get _brut => _lines.fold(0, (s, l) => s + l.total(_kdvDahil));
  double get _toplamIskonto => _lines.fold(0, (s, l) => s + l.discount);
  double get _toplamKdv => _lines.fold(0, (s, l) => s + l.vatAmount(_kdvDahil));
  double get _net => _brut - _toplamIskonto + _toplamKdv;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(_loadError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (_tur == null) {
      return _TurSecimEkrani(onSelected: (t) => setState(() {
            _tur = t;
          }));
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text(widget.taslakId != null ? 'Taslak Düzenle' : 'Yeni Sipariş'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Önizle / Paylaş',
            onPressed: _oncekleVePaylas,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 200),
          children: [
            // Onay durumu — düzenlenen taslakta rozet + reddedildiyse gerekçe.
            if (_onayDurumu != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OnayRozeti(status: _onayDurumu),
              ),
              if (_onayDurumu == 'Rejected' &&
                  (_redGerekce?.isNotEmpty ?? false)) ...[
                const SizedBox(height: AppSpacing.sm),
                RedGerekceKutusu(gerekce: _redGerekce!),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            _TurRozet(tur: _tur!),
            const SizedBox(height: AppSpacing.md),
            _CariSecici(
              selectedCari: _selectedCari,
              kilitli: widget.onceSecilenCari != null,
              onSelect: _selectCari,
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTerminDocRow(
              date: _date,
              onDateChange: (d) => setState(() => _date = d),
              terminDate: _terminDate,
              onTerminChange: (d) => setState(() => _terminDate = d),
              ficheNo: _ficheNoController,
              docCode: _docCodeController,
            ),
            const SizedBox(height: AppSpacing.md),
            _CurrencyRow(
              currencies: _currencies,
              selectedType: _currencyType,
              onChanged: _onCurrencyChanged,
              rateController: _exchangeRateController,
              loadingRate: _loadingExchangeRate,
            ),
            const SizedBox(height: AppSpacing.sm),
            _KdvDahilToggle(kdvDahil: _kdvDahil, onChanged: _toggleKdvDahil),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(
              ikon: Icons.format_list_bulleted_rounded,
              baslik: 'Satırlar (${_lines.length})',
              action: TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ekle'),
              ),
            ),
            if (_lines.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Text('Henüz satır eklenmedi',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.slate500)),
              ),
            for (var i = 0; i < _lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _LineCard(
                  index: i,
                  line: _lines[i],
                  kdvDahil: _kdvDahil,
                  ficheTermin: _terminDate,
                  onChanged: () => setState(() {}),
                  onPickMalzeme: () => _pickMalzemeForLine(i),
                  onPickTermin: () => _pickTerminForLine(i),
                  onDelete: () => _removeLine(i),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(ikon: Icons.notes_rounded, baslik: 'Açıklama'),
            const SizedBox(height: AppSpacing.sm),
            _LabeledField(
              controller: _genExp1Controller,
              label: 'Genel açıklama',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            _ExtraFieldsTile(
              salesmen: _salesmen,
              payPlans: _payPlans,
              selectedSalesman: _selectedSalesman,
              selectedPayDef: _selectedPayDef,
              loading: _loadingLookups,
              error: _lookupError,
              onRetry: _loadLookups,
              onSalesmanChanged: (v) => setState(() => _selectedSalesman = v),
              onPayDefChanged: (v) => setState(() => _selectedPayDef = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _StickyBottom(
        brut: _brut,
        iskonto: _toplamIskonto,
        kdv: _toplamKdv,
        net: _net,
        isSaving: _isSaving,
        onTaslakKaydet: () => _save(transfer: false),
        onAktar: () => _save(transfer: true),
      ),
    );
  }

  // Form'daki mevcut veriden PDF önizleme aç (kaydetmeden de çalışır).
  void _oncekleVePaylas() {
    if (_tur == null) return;
    if (_selectedCari == null || _lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.warning,
        content: Text('Önizleme için cari ve en az bir satır gerekli'),
      ));
      return;
    }
    final ek = <String, String>{};
    if (_terminDate != null) {
      ek['Termin'] = DateFormat('dd.MM.yyyy').format(_terminDate!);
    }
    final data = BelgePdfData(
      belgeBasligi: _tur!.adi,
      durumEtiketi: 'Taslak',
      fisNo: _ficheNoController.text.trim(),
      belgeNo: _docCodeController.text.trim(),
      tarih: _date,
      cariUnvan: _selectedCari!.title,
      cariKod: _selectedCari!.code,
      satirlar: [
        for (var i = 0; i < _lines.length; i++)
          BelgePdfSatir(
            sira: i + 1,
            kod: _lines[i].stockCode ?? '',
            ad: _lines[i].stockName ?? _lines[i].aciklama.text.trim(),
            miktar: _lines[i].amount,
            birim: _lines[i].uomCode ?? '',
            fiyat: _lines[i].priceNet(_kdvDahil),
            kdvOran: _lines[i].vatRate,
            tutar: _lines[i].lineNet(_kdvDahil),
          ),
      ],
      brut: _brut,
      iskonto: _toplamIskonto,
      kdv: _toplamKdv,
      net: _net,
      aciklamalar: _genExp1Controller.text.trim().isEmpty
          ? const []
          : [_genExp1Controller.text.trim()],
      ekBilgiler: ek,
      dosyaAdi: 'TaslakSiparis_${_existingDraftId ?? ''}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BelgeOnizlemeScreen(data: data)),
    );
  }

  // ── Aksiyonlar ──
  Future<void> _selectCari() async {
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

  Future<void> _pickMalzemeForLine(int index) async {
    final result = await Navigator.push<Malzeme>(
      context,
      MaterialPageRoute(
        builder: (_) => const MalzemeListScreen(selectionMode: true),
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _lines[index].setMalzeme(result));

    try {
      final detay = await malzemeService.getMalzemeDetay(result.id);
      if (!mounted) return;
      setState(() {
        final l = _lines[index];
        final isSatis = _tur?.kategori == 'Satış';
        final tanimli = isSatis ? detay.satisFiyati : detay.satinalmaFiyati;
        if (l.priceC.text.trim().isEmpty && tanimli > 0) {
          l.priceC.text = _fmtPlain(tanimli);
        }
      });
    } catch (_) {
      // Detay alınamazsa sessiz geç — kullanıcı manuel girer
    }
  }

  Future<void> _pickTerminForLine(int index) async {
    final l = _lines[index];
    final initial = l.dueDate ?? _terminDate ?? _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      helpText: 'Satır termin tarihi',
    );
    if (picked == null || !mounted) return;
    setState(() => l.dueDate = picked);
  }

  void _toggleKdvDahil(bool yeniDeger) {
    if (yeniDeger == _kdvDahil) return;
    setState(() {
      for (final l in _lines) {
        final p = l.price;
        if (p <= 0) continue;
        final v = l.vatRate;
        if (v <= 0) continue;
        final cevrim = 1 + v / 100;
        final yeniP = yeniDeger ? p * cevrim : p / cevrim;
        l.priceC.text = _fmtPlain(yeniP);
      }
      _kdvDahil = yeniDeger;
    });
  }

  void _addLine() {
    setState(() => _lines.add(_LineDraft()));
  }

  void _removeLine(int i) {
    setState(() {
      _lines[i].dispose();
      _lines.removeAt(i);
    });
  }

  // ── Save / Transfer ──
  Future<void> _save({required bool transfer}) async {
    if (!_validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final rate =
          double.tryParse(_exchangeRateController.text.replaceAll(',', '.')) ??
              1.0;
      final draft = SiparisTaslakModel(
        id: _existingDraftId,
        trCode: _tur!.trCode,
        ficheNo: _ficheNoController.text.trim().isEmpty
            ? null
            : _ficheNoController.text.trim(),
        docCode: _docCodeController.text.trim().isEmpty
            ? null
            : _docCodeController.text.trim(),
        date: _date,
        dueDate: _terminDate,
        clientRef: _selectedCari!.id,
        clientCode: _selectedCari!.code,
        clientTitle: _selectedCari!.title,
        currencyType: _currencyType,
        exchangeRate: _currencyType == 0 ? 1.0 : rate,
        salesmanRef: _selectedSalesman?.id,
        payDefRef: _selectedPayDef?.id,
        genExp1: _genExp1Controller.text.trim().isEmpty
            ? null
            : _genExp1Controller.text.trim(),
        lines: _lines.map((l) => l.toModel(_kdvDahil)).toList(),
      );
      draft.recomputeTotals();

      final saved = _existingDraftId == null
          ? await siparisTaslakService.createTaslak(draft)
          : await siparisTaslakService.updateTaslak(_existingDraftId!, draft);

      if (!mounted) return;
      _existingDraftId = saved.id;

      if (!transfer) {
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.positive,
          content: Text('Taslak kaydedildi (#${saved.id})'),
        ));
        Navigator.pop(context);
        return;
      }

      try {
        final newId = await siparisTaslakService.transferTaslak(saved.id!);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.positive,
          content: Text('LOGO\'ya aktarıldı (#$newId)'),
        ));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 6),
          content: Text('Taslak kaydedildi ancak aktarım başarısız:\n$e'),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.negative,
        content: Text('Kaydedilemedi: $e'),
      ));
      setState(() => _isSaving = false);
    }
  }

  bool _validate() {
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedCari == null) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: AppColors.negative,
        content: Text('Lütfen cari seçin'),
      ));
      return false;
    }
    if (_lines.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: AppColors.negative,
        content: Text('En az bir satır ekleyin'),
      ));
      return false;
    }
    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l.amount <= 0) {
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.negative,
          content: Text('${i + 1}. satırda miktar 0\'dan büyük olmalı'),
        ));
        return false;
      }
      if (l.price <= 0) {
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.negative,
          content: Text('${i + 1}. satırda birim fiyat 0\'dan büyük olmalı'),
        ));
        return false;
      }
      if (l.stockRef == null && (l.aciklama.text.trim()).isEmpty) {
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.negative,
          content: Text('${i + 1}. satıra malzeme seçin veya açıklama girin'),
        ));
        return false;
      }
    }
    return true;
  }
}

// ─── Tür seçim ekranı (yeni sipariş akışının ilk adımı) ────────────────────
class _TurSecimEkrani extends StatelessWidget {
  final ValueChanged<SiparisTuru> onSelected;
  const _TurSecimEkrani({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sipariş Türü Seç'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final t in SiparisTuru.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(t),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: t.renk.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(t.ikon, color: t.renk, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: Text(t.adi, style: AppTypography.body)),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.slate400),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tür rozeti (form üstünde) ──────────────────────────────────────────────
class _TurRozet extends StatelessWidget {
  final SiparisTuru tur;
  const _TurRozet({required this.tur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: tur.renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(tur.ikon, color: tur.renk, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(tur.adi,
                style: AppTypography.bodySmall.copyWith(
                  color: tur.renk,
                  fontWeight: FontWeight.w700,
                )),
          ),
          Text('Öneri',
              style: AppTypography.caption.copyWith(
                color: tur.renk,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ─── Cari seçici ───────────────────────────────────────────────────────────
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
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selectedCari == null ? AppColors.slate300 : AppColors.slate200,
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

// ─── Tarih + termin + fiş no + belge no ────────────────────────────────────
class _DateTerminDocRow extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChange;
  final DateTime? terminDate;
  final ValueChanged<DateTime?> onTerminChange;
  final TextEditingController ficheNo;
  final TextEditingController docCode;

  const _DateTerminDocRow({
    required this.date,
    required this.onDateChange,
    required this.terminDate,
    required this.onTerminChange,
    required this.ficheNo,
    required this.docCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DatePickerTile(
                label: 'Tarih',
                icon: Icons.calendar_today_rounded,
                value: date,
                hint: '',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2099),
                  );
                  if (picked != null) onDateChange(picked);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DatePickerTile(
                label: 'Termin (fiş)',
                icon: Icons.event_available_rounded,
                value: terminDate,
                hint: 'Seç',
                onClear:
                    terminDate != null ? () => onTerminChange(null) : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: terminDate ?? date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2099),
                    helpText: 'Fiş bazlı termin tarihi',
                  );
                  if (picked != null) onTerminChange(picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _LabeledField(
                    controller: ficheNo, label: 'Fiş no (opsiyonel)')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _LabeledField(controller: docCode, label: 'Belge no')),
          ],
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.slate500, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.slate500)),
                    Text(
                      value != null
                          ? DateFormat('dd.MM.yyyy').format(value!)
                          : hint,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: value != null
                            ? AppColors.slate900
                            : AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                InkWell(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.slate400),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Para birimi + kur satırı ──────────────────────────────────────────────
class _CurrencyRow extends StatelessWidget {
  final List<CurrencyModel> currencies;
  final int selectedType;
  final ValueChanged<int?> onChanged;
  final TextEditingController rateController;
  final bool loadingRate;

  const _CurrencyRow({
    required this.currencies,
    required this.selectedType,
    required this.onChanged,
    required this.rateController,
    required this.loadingRate,
  });

  @override
  Widget build(BuildContext context) {
    final isTl = selectedType == 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded,
              color: AppColors.slate500, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: isTl ? 1 : 2,
            child: DropdownButtonFormField<int>(
              initialValue: selectedType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Para Birimi',
                labelStyle:
                    AppTypography.caption.copyWith(color: AppColors.slate500),
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 10),
              ),
              items: currencies
                  .map((c) => DropdownMenuItem(
                        value: c.curType,
                        child: Text(
                          c.curType == 0
                              ? 'TL — Türk Lirası'
                              : '${c.curCode} — ${c.curName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
          if (!isTl) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      labelText: 'Kur',
                      labelStyle: AppTypography.caption
                          .copyWith(color: AppColors.slate500),
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 10),
                    ),
                  ),
                  if (loadingRate)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── KDV dahil/hariç toggle ────────────────────────────────────────────────
class _KdvDahilToggle extends StatelessWidget {
  final bool kdvDahil;
  final ValueChanged<bool> onChanged;

  const _KdvDahilToggle({required this.kdvDahil, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          const Icon(Icons.percent_rounded, color: AppColors.slate500, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Birim fiyatlar KDV dahil',
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  kdvDahil
                      ? 'Girilen fiyatlar KDV dahil — net hesaplanıyor'
                      : 'Girilen fiyatlar KDV hariç — varsayılan',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          Switch(
            value: kdvDahil,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Ek bilgiler (Satış Elemanı + Ödeme Planı) ────────────────────────────
class _ExtraFieldsTile extends StatelessWidget {
  final List<LookupItem> salesmen;
  final List<LookupItem> payPlans;
  final LookupItem? selectedSalesman;
  final LookupItem? selectedPayDef;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<LookupItem?> onSalesmanChanged;
  final ValueChanged<LookupItem?> onPayDefChanged;

  const _ExtraFieldsTile({
    required this.salesmen,
    required this.payPlans,
    required this.selectedSalesman,
    required this.selectedPayDef,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onSalesmanChanged,
    required this.onPayDefChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = selectedSalesman != null || selectedPayDef != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          initiallyExpanded: hasAny || error != null,
          leading: const Icon(Icons.tune_rounded,
              color: AppColors.slate600, size: 20),
          title: Text('Ek Bilgiler (opsiyonel)', style: AppTypography.h3),
          subtitle: Text(
            _subtitle(),
            style: AppTypography.caption.copyWith(
              color: error != null ? AppColors.negative : null,
            ),
          ),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (error != null)
              _errorBox(error!, onRetry)
            else ...[
              _lookupDropdown(
                label: 'Satış Elemanı',
                icon: Icons.person_outline_rounded,
                items: salesmen,
                value: selectedSalesman,
                onChanged: onSalesmanChanged,
                emptyHint: 'LOGO\'da tanımlı satış elemanı bulunamadı',
              ),
              const SizedBox(height: AppSpacing.sm),
              _lookupDropdown(
                label: 'Ödeme Planı',
                icon: Icons.payments_outlined,
                items: payPlans,
                value: selectedPayDef,
                onChanged: onPayDefChanged,
                emptyHint: 'LOGO\'da tanımlı ödeme planı bulunamadı',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    if (loading) return 'Yükleniyor...';
    if (error != null) return 'Yüklenemedi — dokunup yeniden dene';
    return 'Satış elemanı ve ödeme planı';
  }

  Widget _errorBox(String msg, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.negative),
              const SizedBox(width: 6),
              Expanded(
                child: Text(msg,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.negative)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tekrar dene'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.negative,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lookupDropdown({
    required String label,
    required IconData icon,
    required List<LookupItem> items,
    required LookupItem? value,
    required ValueChanged<LookupItem?> onChanged,
    String emptyHint = 'Liste boş',
  }) {
    final effectiveValue = items.contains(value) ? value : null;
    final isEmpty = items.isEmpty;
    return DropdownButtonFormField<LookupItem>(
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.slate500),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.slate500),
        helperText: isEmpty ? emptyHint : null,
        helperStyle: AppTypography.caption.copyWith(color: AppColors.warning),
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<LookupItem>(
          value: null,
          child:
              Text('(seçilmedi)', style: TextStyle(color: AppColors.slate400)),
        ),
        ...items.map((i) => DropdownMenuItem(
              value: i,
              child: Text(
                i.code.isEmpty ? i.name : '${i.code} — ${i.name}',
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: isEmpty ? null : onChanged,
    );
  }
}

// ─── Etiketli text field ───────────────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _LabeledField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.slate500),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 12),
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final Widget? action;

  const _SectionHeader({required this.ikon, required this.baslik, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: AppColors.slate600),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(baslik, style: AppTypography.h3)),
          ?action,
        ],
      ),
    );
  }
}

// ─── Satır draft (mutable, controller'lı) ──────────────────────────────────
class _LineDraft {
  int? id;
  int lineType;
  int? stockRef;
  String? stockCode;
  String? stockName;
  String? uomCode;
  DateTime? dueDate; // satır bazlı termin override
  final TextEditingController amountC;
  final TextEditingController priceC;
  final TextEditingController vatC;
  final TextEditingController discountC;
  final TextEditingController aciklama;

  _LineDraft({
    this.id,
    this.lineType = 0,
    this.stockRef,
    this.stockCode,
    this.stockName,
    this.uomCode,
    this.dueDate,
    String amount = '',
    String price = '',
    String vat = '20',
    String discount = '0',
    String aciklamaText = '',
  })  : amountC = TextEditingController(text: amount),
        priceC = TextEditingController(text: price),
        vatC = TextEditingController(text: vat),
        discountC = TextEditingController(text: discount),
        aciklama = TextEditingController(text: aciklamaText);

  factory _LineDraft.fromTaslak(SiparisTaslakSatirModel l) => _LineDraft(
        id: l.id,
        lineType: l.lineType,
        stockRef: l.stockRef,
        stockCode: l.stockCode,
        stockName: l.stockName,
        uomCode: l.uomCode,
        dueDate: l.dueDate,
        amount: l.amount == 0 ? '' : _fmtPlain(l.amount),
        price: l.price == 0 ? '' : _fmtPlain(l.price),
        vat: l.vatRate == 0 ? '0' : _fmtPlain(l.vatRate),
        discount: l.discount == 0 ? '0' : _fmtPlain(l.discount),
        aciklamaText: l.lineDescription ?? '',
      );

  void setMalzeme(Malzeme m) {
    stockRef = m.id;
    stockCode = m.kod;
    stockName = m.ad;
    uomCode = m.birim;
  }

  double get amount => double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0;
  double get price => double.tryParse(priceC.text.replaceAll(',', '.')) ?? 0;
  double get vatRate => double.tryParse(vatC.text.replaceAll(',', '.')) ?? 0;
  double get discount =>
      double.tryParse(discountC.text.replaceAll(',', '.')) ?? 0;

  double priceNet(bool kdvDahil) =>
      kdvDahil ? price / (1 + vatRate / 100) : price;
  double total(bool kdvDahil) => amount * priceNet(kdvDahil);
  double vatAmount(bool kdvDahil) =>
      (total(kdvDahil) - discount) * vatRate / 100;
  double lineNet(bool kdvDahil) =>
      (total(kdvDahil) - discount) + vatAmount(kdvDahil);

  SiparisTaslakSatirModel toModel(bool kdvDahil) => SiparisTaslakSatirModel(
        id: id,
        lineType: lineType,
        stockRef: stockRef,
        stockCode: stockCode,
        stockName: stockName,
        uomCode: uomCode,
        amount: amount,
        price: priceNet(kdvDahil),
        vatRate: vatRate,
        discount: discount,
        total: total(kdvDahil),
        vatAmount: vatAmount(kdvDahil),
        lineNet: lineNet(kdvDahil),
        dueDate: dueDate,
        lineDescription:
            aciklama.text.trim().isEmpty ? null : aciklama.text.trim(),
      );

  void dispose() {
    amountC.dispose();
    priceC.dispose();
    vatC.dispose();
    discountC.dispose();
    aciklama.dispose();
  }
}

// ─── Satır kartı (form widget) ─────────────────────────────────────────────
class _LineCard extends StatelessWidget {
  final int index;
  final _LineDraft line;
  final bool kdvDahil;
  final DateTime? ficheTermin;
  final VoidCallback onChanged;
  final VoidCallback onPickMalzeme;
  final VoidCallback onPickTermin;
  final VoidCallback onDelete;

  const _LineCard({
    required this.index,
    required this.line,
    required this.kdvDahil,
    required this.ficheTermin,
    required this.onChanged,
    required this.onPickMalzeme,
    required this.onPickTermin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final effektifTermin = line.dueDate ?? ficheTermin;
    final terminOverride = line.dueDate != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.slate100,
                child: Text('${index + 1}',
                    style: AppTypography.caption
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Material(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onPickMalzeme,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 16, color: AppColors.slate500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              line.stockName ?? 'Malzeme seç',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: line.stockName == null
                                    ? AppColors.slate400
                                    : AppColors.slate900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded,
                              size: 16, color: AppColors.slate400),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.slate400),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _NumField(
                  controller: line.amountC,
                  label: 'Miktar',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: _NumField(
                  controller: line.priceC,
                  label: kdvDahil ? 'Birim fiyat (KDV dahil)' : 'Birim fiyat',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 64,
                child: _NumField(
                  controller: line.vatC,
                  label: 'KDV %',
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Satır termin chip — boşsa fiş termini geçerli
              Expanded(
                child: Material(
                  color: terminOverride
                      ? AppColors.accent.withValues(alpha: 0.10)
                      : AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onPickTermin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded,
                              size: 14,
                              color: terminOverride
                                  ? AppColors.accent
                                  : AppColors.slate500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              effektifTermin != null
                                  ? 'Termin: ${DateFormat('dd.MM.yyyy').format(effektifTermin)}'
                                      '${terminOverride ? '' : ' (fiş)'}'
                                  : 'Termin ekle',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: effektifTermin != null
                                    ? AppColors.slate700
                                    : AppColors.slate400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Toplam: ',
                        style: AppTypography.caption),
                    Text(_fmtCurrency(line.lineNet(kdvDahil)),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _NumField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.body,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.slate500),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 10),
      ),
    );
  }
}

// ─── Sticky bottom (toplamlar + butonlar) ──────────────────────────────────
class _StickyBottom extends StatelessWidget {
  final double brut, iskonto, kdv, net;
  final bool isSaving;
  final VoidCallback onTaslakKaydet;
  final VoidCallback onAktar;

  const _StickyBottom({
    required this.brut,
    required this.iskonto,
    required this.kdv,
    required this.net,
    required this.isSaving,
    required this.onTaslakKaydet,
    required this.onAktar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _toplamMini('Brüt', brut)),
                  Expanded(child: _toplamMini('İskonto', iskonto, neg: true)),
                  Expanded(child: _toplamMini('KDV', kdv)),
                  Expanded(child: _toplamMini('Net', net, bold: true)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Onay zorunlu: form yalnızca taslak kaydeder (onaya düşer).
              // Aktarım, patron onayından sonra listeden yapılır.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onTaslakKaydet,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving
                      ? 'Kaydediliyor...'
                      : 'Taslak Kaydet (Onaya Gönder)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toplamMini(String l, double v, {bool bold = false, bool neg = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: AppTypography.caption.copyWith(color: AppColors.slate500)),
        Text(
          _fmtCurrency(v),
          style: bold
              ? AppTypography.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                )
              : AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: neg && v > 0 ? AppColors.negative : AppColors.slate700,
                ),
        ),
      ],
    );
  }
}

// ─── helpers ───────────────────────────────────────────────────────────────
String _fmtCurrency(double v) =>
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
        .format(v);
String _fmtPlain(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}
