import 'package:flutter/material.dart';
import '../../core/auth/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'user_model.dart';
import 'user_service.dart';

/// Kullanıcı ekleme/düzenleme formu. [user] null ise yeni kullanıcı.
class UserFormScreen extends StatefulWidget {
  final AppUser? user;
  const UserFormScreen({super.key, this.user});

  bool get isEdit => user != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();

  // Yeni kullanıcı varsayılanı en az yetkili rol (güvenli).
  String _role = AppRole.satisci.value;
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _fullNameCtrl = TextEditingController(text: u?.fullName ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    // Eski "User"/"Admin" değerleri de normalize edilir (fromString → value).
    _role = u != null
        ? AppRole.fromString(u.role).value
        : AppRole.satisci.value;
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEdit) {
        await userService.updateUser(
          id: widget.user!.id,
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          role: _role,
          isActive: _isActive,
          password: _passwordCtrl.text,
        );
      } else {
        await userService.createUser(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          role: _role,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Kullanıcıyı Düzenle' : 'Yeni Kullanıcı',
          style: AppTypography.h2,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: AppSpacing.md),
            ],
            _FieldLabel('Kullanıcı Adı'),
            TextFormField(
              controller: _usernameCtrl,
              enabled: !widget.isEdit, // düzenlemede değiştirilemez
              decoration: _dec(widget.isEdit ? null : 'örn. ahmet.yilmaz'),
              validator: (v) => (widget.isEdit || (v != null && v.trim().isNotEmpty))
                  ? null
                  : 'Kullanıcı adı zorunlu',
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldLabel('Ad Soyad'),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: _dec('örn. Ahmet Yılmaz'),
              validator: (v) =>
                  (v != null && v.trim().isNotEmpty) ? null : 'Ad Soyad zorunlu',
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldLabel('E-posta'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('örn. ahmet@firma.com'),
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldLabel('Rol'),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: _dec(null),
              items: AppRole.values
                  .map((r) =>
                      DropdownMenuItem(value: r.value, child: Text(r.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _role = v ?? AppRole.satisci.value),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                AppRole.fromString(_role).aciklama,
                style:
                    AppTypography.caption.copyWith(color: AppColors.slate500),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldLabel(widget.isEdit
                ? 'Yeni Şifre (boş bırakırsanız değişmez)'
                : 'Şifre'),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: _dec('••••••••'),
              validator: (v) {
                if (widget.isEdit) return null; // edit'te opsiyonel
                if (v == null || v.length < 4) return 'En az 4 karakter';
                return null;
              },
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: SwitchListTile(
                  value: _isActive,
                  activeThumbColor: AppColors.accent,
                  title: Text('Aktif', style: AppTypography.body),
                  subtitle: Text(
                    _isActive ? 'Giriş yapabilir' : 'Giriş engellendi',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.slate500),
                  ),
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
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
                    : Text(widget.isEdit ? 'Kaydet' : 'Oluştur',
                        style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
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
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.slate600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.negative.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.negative, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}
