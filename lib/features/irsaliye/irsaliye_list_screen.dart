import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/onay_rozeti.dart';
import '../auth/auth_service.dart';
import 'irsaliye_detay_screen.dart';
import 'irsaliye_form_screen.dart';
import 'irsaliye_model.dart';
import 'irsaliye_service.dart';
import 'irsaliye_taslak_service.dart';

/// İrsaliye listesi — 3 sekme: Logo / Taslaklar / Hatalı.
class IrsaliyeListScreen extends StatefulWidget {
  final int? cariIdFilter;
  const IrsaliyeListScreen({super.key, this.cariIdFilter});

  @override
  State<IrsaliyeListScreen> createState() => _IrsaliyeListScreenState();
}

class _IrsaliyeListScreenState extends State<IrsaliyeListScreen>
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
        title: const Text('İrsaliyeler'),
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
          labelStyle:
              AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Logo'),
            Tab(text: 'Taslaklar'),
            Tab(text: 'Hatalı'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IrsaliyeListTab(
              mode: _ListMode.logo, cariIdFilter: widget.cariIdFilter),
          const _IrsaliyeListTab(mode: _ListMode.taslak),
          const _IrsaliyeListTab(mode: _ListMode.hatali),
        ],
      ),
      floatingActionButton: authService.perms.canCreateBelge
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IrsaliyeFormScreen()),
                );
                if (!mounted) return;
                setState(() {});
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni İrsaliye'),
            )
          : null,
    );
  }
}

enum _ListMode { logo, taslak, hatali }

class _IrsaliyeListTab extends StatefulWidget {
  final _ListMode mode;
  final int? cariIdFilter;
  const _IrsaliyeListTab({required this.mode, this.cariIdFilter});

  @override
  State<_IrsaliyeListTab> createState() => _IrsaliyeListTabState();
}

class _IrsaliyeListTabState extends State<_IrsaliyeListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<IrsaliyeModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _searchQuery = '';
  int _offset = 0;
  static const int _pageSize = 30;

  // Sadece Logo sekmesinde kullanılan filtreler
  String _kategoriFilter = 'hepsi';
  bool? _faturaFilter; // null=hepsi, false=faturalanmamış, true=faturalanmış

  @override
  bool get wantKeepAlive => true;

  // Kategori → tek TRCODE (backend tek değer alıyor)
  int? _trCodeForKategori() {
    switch (_kategoriFilter) {
      case 'satis_perakende':
        return 7;
      case 'satis_toptan':
        return 8;
      case 'satinalma':
        return 1;
      case 'satis_iade_perakende':
        return 2;
      case 'satis_iade_toptan':
        return 3;
      case 'satinalma_iade':
        return 6;
      default:
        return null;
    }
  }

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
      List<IrsaliyeModel> page;
      final search = _searchQuery.isEmpty ? null : _searchQuery;
      switch (widget.mode) {
        case _ListMode.logo:
          page = await irsaliyeService.getIrsaliyeler(
            offset: _offset,
            limit: _pageSize,
            search: search,
            trCode: _trCodeForKategori(),
            faturalandi: _faturaFilter,
            cariId: widget.cariIdFilter,
          );
          break;
        case _ListMode.taslak:
          page = await irsaliyeTaslakService.getTaslaklar(
            status: 'Draft',
            offset: _offset,
            limit: _pageSize,
            search: search,
          );
          break;
        case _ListMode.hatali:
          page = await irsaliyeTaslakService.getTaslaklar(
            status: 'Failed',
            offset: _offset,
            limit: _pageSize,
            search: search,
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

  Future<void> _refresh() async => _load(reset: true);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildSearchBar(),
        if (widget.mode == _ListMode.logo) _buildFilters(),
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
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _kategoriChip(label: 'Hepsi', kod: 'hepsi'),
            const SizedBox(width: AppSpacing.sm),
            _kategoriChip(
                label: 'Satış (Toptan)',
                kod: 'satis_toptan',
                icon: Icons.local_shipping_rounded,
                color: AppColors.positive),
            const SizedBox(width: AppSpacing.sm),
            _kategoriChip(
                label: 'Satış (Perakende)',
                kod: 'satis_perakende',
                icon: Icons.local_shipping_rounded,
                color: AppColors.positive),
            const SizedBox(width: AppSpacing.sm),
            _kategoriChip(
                label: 'Satınalma',
                kod: 'satinalma',
                icon: Icons.inventory_2_rounded,
                color: AppColors.cyan),
            const SizedBox(width: AppSpacing.sm),
            _kategoriChip(
                label: 'Satış İade (Toptan)',
                kod: 'satis_iade_toptan',
                icon: Icons.assignment_return_rounded,
                color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            _kategoriChip(
                label: 'Satış İade (Perakende)',
                kod: 'satis_iade_perakende',
                icon: Icons.assignment_return_rounded,
                color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            _kategoriChip(
                label: 'Satınalma İade',
                kod: 'satinalma_iade',
                icon: Icons.assignment_return_rounded,
                color: AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            Container(width: 1, height: 24, color: AppColors.slate200),
            const SizedBox(width: AppSpacing.md),
            _faturaChip('Faturalanmamış', false,
                icon: Icons.unpublished_outlined),
            const SizedBox(width: AppSpacing.sm),
            _faturaChip('Faturalanmış', true, icon: Icons.task_alt_rounded),
          ],
        ),
      ),
    );
  }

  Widget _kategoriChip({
    required String label,
    required String kod,
    IconData? icon,
    Color? color,
  }) {
    final selected = _kategoriFilter == kod;
    final effective = color ?? AppColors.slate600;
    return Material(
      color: selected ? effective.withValues(alpha: 0.12) : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _kategoriFilter = kod);
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

  Widget _faturaChip(String label, bool kod, {IconData? icon}) {
    final selected = _faturaFilter == kod;
    final renk = kod ? AppColors.positive : AppColors.warning;
    return Material(
      color: selected ? renk.withValues(alpha: 0.12) : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _faturaFilter = selected ? null : kod);
          _load(reset: true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? renk : AppColors.slate200),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14, color: selected ? renk : AppColors.slate500),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? renk : AppColors.slate700,
                  )),
            ],
          ),
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
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.slate400),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.slate400),
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
          child: _IrsaliyeCard(
            item: _items[index],
            mode: widget.mode,
            onTap: () => _openDetay(_items[index]),
            onEdit: widget.mode != _ListMode.logo
                ? () => _editTaslak(_items[index])
                : null,
            onTransfer: widget.mode != _ListMode.logo
                ? () => _transferTaslak(_items[index])
                : null,
            onDelete: widget.mode != _ListMode.logo
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
      case _ListMode.logo:
        msg = _searchQuery.isEmpty ? 'Henüz irsaliye yok' : 'Sonuç bulunamadı';
        icon = Icons.local_shipping_outlined;
        break;
      case _ListMode.taslak:
        msg = 'Taslak irsaliye yok\n+ Yeni İrsaliye ile başlayın';
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

  Future<void> _openDetay(IrsaliyeModel i) async {
    if (widget.mode != _ListMode.logo) {
      _editTaslak(i);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IrsaliyeDetayScreen(id: i.id)),
    );
    if (!mounted) return;
    _load(reset: true);
  }

  Future<void> _editTaslak(IrsaliyeModel i) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IrsaliyeFormScreen(taslakId: i.id)),
    );
    if (!mounted) return;
    _load(reset: true);
  }

  Future<void> _transferTaslak(IrsaliyeModel i) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newId = await irsaliyeTaslakService.transferTaslak(i.id);
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

  Future<void> _deleteTaslak(IrsaliyeModel i) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Taslak silinsin mi?'),
        content: Text(
            '${i.clientTitle} — ${_fmtCurrency(i.netTotal)}\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
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
      await irsaliyeTaslakService.deleteTaslak(i.id);
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

class _IrsaliyeCard extends StatelessWidget {
  final IrsaliyeModel item;
  final _ListMode mode;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onTransfer;
  final VoidCallback? onDelete;

  const _IrsaliyeCard({
    required this.item,
    required this.mode,
    required this.onTap,
    this.onEdit,
    this.onTransfer,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tur = item.tur;
    final renk = tur?.renk ?? AppColors.slate500;
    final ikon = tur?.ikon ?? Icons.local_shipping_rounded;

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
                      color: renk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ikon, color: renk, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.clientTitle.isEmpty
                              ? '(Cari yok)'
                              : item.clientTitle,
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tur?.adi ?? "Tip ${item.trCode}"} • ${item.ficheNo.isEmpty ? "(Fiş no yok)" : item.ficheNo}',
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
                        _fmtCurrency(item.netTotal),
                        style: AppTypography.h3.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_fmtDate(item.date), style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
              if (mode == _ListMode.logo) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (item.isFaturalandi)
                      _badge('Faturalandı', AppColors.positive,
                          icon: Icons.task_alt_rounded)
                    else
                      _badge('Faturalanmamış', AppColors.warning,
                          icon: Icons.unpublished_outlined),
                    if (item.invNo.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text('Fat: ${item.invNo}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.slate500)),
                    ],
                  ],
                ),
              ],
              if (item.isDraft && item.approvalStatus != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OnayRozeti(status: item.approvalStatus),
                ),
              ],
              if (item.isReddedildi && (item.rejectReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: AppSpacing.sm),
                RedGerekceKutusu(gerekce: item.rejectReason!),
              ],
              if (mode == _ListMode.hatali && item.lastError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 6),
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
                          item.lastError!,
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
              if (mode != _ListMode.logo) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _ActionBtn(
                        icon: Icons.edit_rounded,
                        label: 'Düzenle',
                        onTap: onEdit),
                    if (authService.perms.canTransferBelge &&
                        item.isOnaylandi) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _ActionBtn(
                        icon: mode == _ListMode.hatali
                            ? Icons.refresh_rounded
                            : Icons.cloud_upload_rounded,
                        label:
                            mode == _ListMode.hatali ? 'Tekrar Dene' : 'Aktar',
                        onTap: onTransfer,
                        primary: true,
                      ),
                    ],
                    const Spacer(),
                    if (authService.perms.canDeleteBelge)
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

  Widget _badge(String text, Color color, {IconData? icon}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: AppTypography.caption
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
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
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtCurrency(double v) =>
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
        .format(v);
String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
