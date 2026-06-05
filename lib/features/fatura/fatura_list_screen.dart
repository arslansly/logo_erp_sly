import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'fatura_detay_screen.dart';
import 'fatura_form_screen.dart';
import 'fatura_model.dart';
import 'fatura_service.dart';
import 'fatura_taslak_service.dart';

/// Fatura listesi — 3 sekme: Aktarılan / Taslaklar / Hatalı.
class FaturaListScreen extends StatefulWidget {
  const FaturaListScreen({super.key});

  @override
  State<FaturaListScreen> createState() => _FaturaListScreenState();
}

class _FaturaListScreenState extends State<FaturaListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faturalar'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTypography.h2,
        foregroundColor: AppColors.slate900,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate500,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Aktarılan'),
            Tab(text: 'Taslaklar'),
            Tab(text: 'Hatalı'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FaturaListTab(mode: _ListMode.aktarilan),
          _FaturaListTab(mode: _ListMode.taslak),
          _FaturaListTab(mode: _ListMode.hatali),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaturaFormScreen()),
          );
          if (!mounted) return;
          // Form kapanınca taslak/hatalı sekmelerini tazele
          setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Fatura'),
      ),
    );
  }
}

enum _ListMode { aktarilan, taslak, hatali }

class _FaturaListTab extends StatefulWidget {
  final _ListMode mode;
  const _FaturaListTab({required this.mode});

  @override
  State<_FaturaListTab> createState() => _FaturaListTabState();
}

class _FaturaListTabState extends State<_FaturaListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<FaturaModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _searchQuery = '';
  int _offset = 0;
  static const int _pageSize = 30;

  // Sadece "Aktarılan" sekmesinde kullanılan kategori filtresi
  String? _kategoriFilter; // 'Satış' | 'Satınalma' | 'İade'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    if (max - pos < 300 && !_isLoadingMore && _hasMore && !_isLoading) {
      _load();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
      _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _hasMore = true;
        _error = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      List<FaturaModel> page;
      switch (widget.mode) {
        case _ListMode.aktarilan:
          page = await faturaService.getFaturalar(
            offset: _offset,
            limit: _pageSize,
            search: _searchQuery.isEmpty ? null : _searchQuery,
            kategori: _kategoriFilter,
          );
          break;
        case _ListMode.taslak:
          page = await faturaTaslakService.getTaslaklar(
            status: 'Draft',
            offset: _offset,
            limit: _pageSize,
            search: _searchQuery.isEmpty ? null : _searchQuery,
          );
          break;
        case _ListMode.hatali:
          page = await faturaTaslakService.getTaslaklar(
            status: 'Failed',
            offset: _offset,
            limit: _pageSize,
            search: _searchQuery.isEmpty ? null : _searchQuery,
          );
          break;
      }
      if (!mounted) return;
      setState(() {
        if (reset) _items = [];
        _items.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _pageSize;
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

  Future<void> _refresh() async {
    await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildSearchBar(),
        if (widget.mode == _ListMode.aktarilan) _buildFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.accent,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, String? kategori, {IconData? icon, Color? color}) {
      final selected = _kategoriFilter == kategori;
      final effective = color ?? AppColors.slate600;
      return Material(
        color: selected ? effective.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() => _kategoriFilter = kategori);
            _load(reset: true);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: selected ? effective : AppColors.slate200),
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
                      fontWeight: FontWeight.w600,
                      color: selected ? effective : AppColors.slate700,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Hepsi', null),
            const SizedBox(width: AppSpacing.sm),
            chip('Satış', 'Satış',
                icon: Icons.trending_up_rounded, color: AppColors.positive),
            const SizedBox(width: AppSpacing.sm),
            chip('Alış', 'Satınalma',
                icon: Icons.trending_down_rounded, color: AppColors.cyan),
            const SizedBox(width: AppSpacing.sm),
            chip('İade', 'İade',
                icon: Icons.undo_rounded, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: 'Fiş no, belge no, cari ara...',
            hintStyle: AppTypography.body.copyWith(color: AppColors.slate400),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _load(reset: true);
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) return _buildSkeleton();
    if (_error != null && _items.isEmpty) return _buildError();
    if (_items.isEmpty) return _buildEmpty();

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _FaturaKarti(
            fatura: _items[index],
            mode: widget.mode,
            onTap: () => _openDetay(_items[index]),
            onEdit: widget.mode != _ListMode.aktarilan
                ? () => _editTaslak(_items[index])
                : null,
            onTransfer: widget.mode != _ListMode.aktarilan
                ? () => _transferTaslak(_items[index])
                : null,
            onDelete: widget.mode != _ListMode.aktarilan
                ? () => _deleteTaslak(_items[index])
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.slate300),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(_error ?? 'Hata',
              style: AppTypography.body.copyWith(color: AppColors.slate600),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    String msg;
    IconData icon;
    switch (widget.mode) {
      case _ListMode.aktarilan:
        msg = _searchQuery.isEmpty ? 'Henüz fatura yok' : 'Sonuç bulunamadı';
        icon = Icons.receipt_long_outlined;
        break;
      case _ListMode.taslak:
        msg = 'Taslak fatura yok\n+ Yeni Fatura ile başlayın';
        icon = Icons.drafts_outlined;
        break;
      case _ListMode.hatali:
        msg = 'Hatalı taslak yok';
        icon = Icons.check_circle_outline_rounded;
        break;
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: AppColors.slate300),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(msg,
              style: AppTypography.body.copyWith(color: AppColors.slate500),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Future<void> _openDetay(FaturaModel f) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaturaDetayScreen(fatura: f)),
    );
    if (!mounted) return;
    _load(reset: true);
  }

  Future<void> _editTaslak(FaturaModel f) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaturaFormScreen(taslakId: f.id)),
    );
    if (!mounted) return;
    _load(reset: true);
  }

  Future<void> _transferTaslak(FaturaModel f) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newId = await faturaTaslakService.transferTaslak(f.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.positive,
        content: Text('LOGO\'ya aktarıldı (#$newId)'),
      ));
      _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.negative,
        content: Text('Aktarım başarısız: $e'),
        duration: const Duration(seconds: 5),
      ));
      _load(reset: true);
    }
  }

  Future<void> _deleteTaslak(FaturaModel f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Taslak silinsin mi?'),
        content: Text('${f.clientTitle} — ${_fmtCurrency(f.netTotal)}\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await faturaTaslakService.deleteTaslak(f.id);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Taslak silindi')));
      _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.negative,
        content: Text('Silinemedi: $e'),
      ));
    }
  }
}

// ─── Fatura kartı widget'ı ─────────────────────────────────────────────────
class _FaturaKarti extends StatelessWidget {
  final FaturaModel fatura;
  final _ListMode mode;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTransfer;
  final VoidCallback? onDelete;

  const _FaturaKarti({
    required this.fatura,
    required this.mode,
    required this.onTap,
    this.onEdit,
    this.onTransfer,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ikonRengi = fatura.displayRenk;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ikonRengi.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(fatura.displayIkon, color: ikonRengi, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fatura.clientTitle.isEmpty ? '(Cari yok)' : fatura.clientTitle,
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fatura.displayAd} • ${fatura.ficheNo.isEmpty ? "(Fiş no yok)" : fatura.ficheNo}',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtCurrency(fatura.netTotal),
                        style: AppTypography.h3.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(fatura.date),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
              if (mode == _ListMode.hatali && fatura.lastError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.negativeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.negative),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fatura.lastError!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.negative,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (mode != _ListMode.aktarilan) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_rounded,
                      label: 'Düzenle',
                      onTap: onEdit,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ActionBtn(
                      icon: mode == _ListMode.hatali
                          ? Icons.refresh_rounded
                          : Icons.cloud_upload_rounded,
                      label: mode == _ListMode.hatali ? 'Tekrar Dene' : 'Aktar',
                      onTap: onTransfer,
                      primary: true,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.slate400,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.primary : AppColors.slate100;
    final fg = primary ? AppColors.surface : AppColors.slate700;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.caption.copyWith(
                color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtCurrency(double v) {
  final f = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  return f.format(v);
}

String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
