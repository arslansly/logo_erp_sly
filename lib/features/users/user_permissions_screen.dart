import 'package:flutter/material.dart';
import '../../core/auth/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'user_model.dart';
import 'user_service.dart';

/// Bir kullanıcının yetki istisnalarını (override) düzenleme ekranı.
/// Her yetki için üç durum: Rol varsayılanı / Aç / Kapat.
/// Sunucu rol varsayılanını + effective sonucu kendisi hesaplar; burada
/// yalnızca gösterip override kararlarını geri gönderiyoruz.
class UserPermissionsScreen extends StatefulWidget {
  final AppUser user;
  const UserPermissionsScreen({super.key, required this.user});

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  bool _loading = true;
  String? _error;
  bool _saving = false;

  UserPermissions? _data;
  // key → seçim: null = rol varsayılanı, true = aç (override), false = kapat (override)
  final Map<String, bool?> _choice = {};

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
      final data = await userService.getUserPermissions(widget.user.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _choice
          ..clear()
          ..addEntries(data.items.map((i) => MapEntry(i.key, i.overrideValue)));
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

  Future<void> _save() async {
    setState(() => _saving = true);
    final overrides = <String, bool>{};
    _choice.forEach((k, v) {
      if (v != null) overrides[k] = v;
    });
    try {
      await userService.setUserPermissions(widget.user.id, overrides);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yetkiler güncellendi'),
          backgroundColor: AppColors.positive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.negative,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel =
        _data != null ? AppRole.fromString(_data!.role).label : '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yetkiler', style: AppTypography.h2),
            Text(
              widget.user.fullName.isEmpty
                  ? widget.user.username
                  : '${widget.user.fullName} · $roleLabel',
              style: AppTypography.caption.copyWith(color: AppColors.slate500),
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: (_data == null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Kaydet', style: AppTypography.button),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    final items = _data!.items;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        if (i == 0) return _buildInfo();
        return _buildRow(items[i - 1]);
      },
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.accentDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Her yetki rol varsayılanını kullanır. Gerektiğinde bu kullanıcıya '
              'özel "Aç" veya "Kapat" istisnası koyabilirsin.',
              style: AppTypography.caption.copyWith(color: AppColors.slate600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(PermissionItem item) {
    final choice = _choice[item.key]; // null=varsayılan, true=aç, false=kapat
    final effective = choice ?? item.defaultGranted;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Perm.label(item.key),
                  style: AppTypography.body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                effective
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: effective ? AppColors.positive : AppColors.slate400,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Rol varsayılanı: ${item.defaultGranted ? "Açık" : "Kapalı"}',
            style: AppTypography.caption.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _seg('Varsayılan', choice == null, AppColors.slate600,
                  () => setState(() => _choice[item.key] = null)),
              const SizedBox(width: AppSpacing.sm),
              _seg('Aç', choice == true, AppColors.positive,
                  () => setState(() => _choice[item.key] = true)),
              const SizedBox(width: AppSpacing.sm),
              _seg('Kapat', choice == false, AppColors.negative,
                  () => setState(() => _choice[item.key] = false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seg(String label, bool selected, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? color : AppColors.slate200),
            ),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? color : AppColors.slate600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.slate400),
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.slate600),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
