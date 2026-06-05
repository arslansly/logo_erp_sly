import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'malzeme_detay_screen.dart';
import 'malzeme_image.dart';
import 'malzeme_model.dart';
import 'malzeme_service.dart';

class MalzemeListScreen extends StatefulWidget {
  /// `true` ise tıklanan malzeme `Navigator.pop(context, malzeme)` ile döner;
  /// detay ekranına push yapılmaz. Fatura formu malzeme seçici için kullanır.
  final bool selectionMode;
  const MalzemeListScreen({super.key, this.selectionMode = false});

  @override
  State<MalzemeListScreen> createState() => _MalzemeListScreenState();
}

class _MalzemeListScreenState extends State<MalzemeListScreen> {
  static const int _limit = 50;

  final List<Malzeme> _malzemeler = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;

  String _searchQuery = '';
  bool _sadeceStokYok = false; // 'Stoğu olmayanlar' filtresi açık mı?
  int? _turFilter; // CARDTYPE filtresi (null = tüm türler)
  Timer? _debounce;

  // Servise gidecek stok durumu:
  // - Seçim modunda: varsayılan tümü (null), filtre açıksa sadece 'yok'.
  // - Stok ekranında: varsayılan sadece stoğu olanlar ('var'), filtre açıksa 'yok'.
  String? get _stokDurumu {
    if (_sadeceStokYok) return 'yok';
    return widget.selectionMode ? null : 'var';
  }

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadData(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.offset >= threshold &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      if (!mounted) return;
      setState(() {
        _malzemeler.clear();
        _offset = 0;
        _hasMore = true;
        _error = null;
        _isLoading = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      if (!mounted) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final results = await malzemeService.getMalzemeler(
        offset: reset ? 0 : _offset,
        limit: _limit,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        stokDurumu: _stokDurumu,
        tur: _turFilter,
      );

      if (!mounted) return;
      setState(() {
        _malzemeler.addAll(results);
        _offset = _malzemeler.length;
        _hasMore = results.length == _limit;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value != _searchQuery) {
        _searchQuery = value;
        _loadData(reset: true);
      }
    });
  }

  Future<void> _refresh() async {
    await _loadData(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Malzeme Seç' : 'Stok'),
        titleTextStyle: AppTypography.h1.copyWith(
          color: AppColors.slate900,
          fontSize: 22,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildFilters(),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Malzeme ara — ad, kod...',
          hintStyle:
              AppTypography.body.copyWith(color: AppColors.slate500, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.slate500, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTypography.body.copyWith(fontSize: 14),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Stoğu olmayanlar toggle
          _chip(
            label: 'Stoğu olmayanlar',
            icon: Icons.inventory_2_outlined,
            color: AppColors.negative,
            selected: _sadeceStokYok,
            onTap: () {
              setState(() => _sadeceStokYok = !_sadeceStokYok);
              _loadData(reset: true);
            },
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 22, color: AppColors.slate200),
          const SizedBox(width: 10),
          // Tür filtreleri
          _chip(
            label: 'Tüm türler',
            selected: _turFilter == null,
            onTap: () {
              if (_turFilter == null) return;
              setState(() => _turFilter = null);
              _loadData(reset: true);
            },
          ),
          for (final t in MalzemeTur.values) ...[
            const SizedBox(width: 8),
            _chip(
              label: t.adi,
              color: AppColors.accent,
              selected: _turFilter == t.cardType,
              onTap: () {
                setState(() =>
                    _turFilter = _turFilter == t.cardType ? null : t.cardType);
                _loadData(reset: true);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    IconData? icon,
    Color? color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final effective = color ?? AppColors.slate600;
    return Material(
      color: selected ? effective.withValues(alpha: 0.12) : AppColors.slate100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? effective : AppColors.slate200),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: selected ? effective : AppColors.slate500),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: AppTypography.caption.copyWith(
                    color: selected ? effective : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null && _malzemeler.isEmpty) return _buildErrorState(_error!);
    if (_malzemeler.isEmpty) return _buildEmptyState();
    return _buildList();
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _malzemeler.length + (_isLoadingMore || _hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _malzemeler.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                )
              : const SizedBox(height: 16);
        }
        final m = _malzemeler[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _malzemeler.length - 1 ? 10 : 0),
          child: _MalzemeCard(
            malzeme: m,
            onTap: () {
              if (widget.selectionMode) {
                Navigator.of(context).pop(m);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MalzemeDetayScreen(malzemeId: m.id, initialMalzeme: m),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.negativeBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.negative, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Bağlantı sorunu', style: AppTypography.h2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.slate600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: AppColors.slate400),
          const SizedBox(height: 12),
          Text('Sonuç bulunamadı',
              style: AppTypography.h2.copyWith(color: AppColors.slate600)),
        ],
      ),
    );
  }
}

class _TurChip extends StatelessWidget {
  final String tur;
  const _TurChip({required this.tur});

  String get _kisaltma => switch (tur) {
        'Hammadde' => 'HM',
        'Yarı Mamul' => 'YM',
        _ => tur,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _kisaltma,
        style: AppTypography.caption.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MalzemeCard extends StatelessWidget {
  final Malzeme malzeme;
  final VoidCallback onTap;

  const _MalzemeCard({required this.malzeme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('tr_TR');
    final stokRenk =
        malzeme.stokYok ? AppColors.negative : AppColors.positive;
    final stokBgRenk =
        malzeme.stokYok ? AppColors.negativeBg : AppColors.positiveBg;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MalzemeImage(malzemeId: malzeme.id, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      malzeme.ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(
                          color: AppColors.slate900, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            malzeme.grupKodu.isEmpty
                                ? malzeme.kod
                                : '${malzeme.kod} · ${malzeme.grupKodu}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                                color: AppColors.slate500, fontSize: 11),
                          ),
                        ),
                        if (malzeme.tur.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _TurChip(tur: malzeme.tur),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stokBgRenk,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${fmt.format(malzeme.fiiliStok)} ${malzeme.birim}',
                      style: AppTypography.caption.copyWith(
                        color: stokRenk,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (malzeme.rezerveli > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${fmt.format(malzeme.rezerveli)} rezerveli',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
