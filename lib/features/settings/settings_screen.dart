import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'settings_model.dart';
import 'settings_service.dart';

/// Giriş ekranından açılan bağlantı ayarları:
/// sunucu adresi + LOGO firma/dönem numarası. Giriş öncesi (token gerekmez).
/// Görsel olarak giriş ekranıyla aynı koyu "editorial" dilde.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Giriş ekranıyla aynı palet (login_screen._EdPalette ile uyumlu).
class _SettingsPalette {
  static const bg = Color(0xFF000000);
  static const text = Color(0xFFFFFFFF);
  static const textDim = Color(0x80FFFFFF);
  static const textMute = Color(0x59FFFFFF);
  static const hairline = Color(0x29FFFFFF);
  static const accent = Color(0xFF10B981);
  static const negative = Color(0xFFF87171);
}

enum _TestState { idle, loading, success, error }

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _firmaCtrl = TextEditingController();
  final _donemCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  _TestState _testState = _TestState.idle;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _firmaCtrl.dispose();
    _donemCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await settingsService.load();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = config.serverUrl;
      _firmaCtrl.text = config.firmaNo;
      _donemCtrl.text = config.donemNo;
      _loading = false;
    });
  }

  // ─── Bağlantı testi ───
  Future<void> _testConnection() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testState = _TestState.error;
        _testMessage = 'Sunucu adresi boş olamaz';
      });
      return;
    }
    setState(() {
      _testState = _TestState.loading;
      _testMessage = null;
    });
    try {
      await settingsService.testConnection(url);
      if (!mounted) return;
      setState(() {
        _testState = _TestState.success;
        _testMessage = 'Bağlantı başarılı';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testState = _TestState.error;
        _testMessage = e.toString();
      });
    }
  }

  // ─── Kaydet ───
  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    final firma = _firmaCtrl.text.trim();
    final donem = _donemCtrl.text.trim();

    if (url.isEmpty || firma.isEmpty || donem.isEmpty) {
      setState(() {
        _testState = _TestState.error;
        _testMessage = 'Tüm alanlar zorunlu';
      });
      return;
    }

    setState(() => _saving = true);
    await settingsService.save(
      AppConfig(serverUrl: url, firmaNo: firma, donemNo: donem),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayarlar kaydedildi'),
        backgroundColor: _SettingsPalette.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SettingsPalette.bg,
      appBar: AppBar(
        backgroundColor: _SettingsPalette.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _SettingsPalette.text),
        title: Text(
          'Ayarlar',
          style: AppTypography.h2.copyWith(color: _SettingsPalette.text),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _SettingsPalette.accent),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                children: [
                  _sectionLabel('SUNUCU'),
                  const SizedBox(height: AppSpacing.md),
                  _HairlineField(
                    label: 'SUNUCU ADRESİ',
                    controller: _urlCtrl,
                    hint: 'http://192.168.1.10:5249',
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() => _testState = _TestState.idle),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTestRow(),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionLabel('FİRMA / DÖNEM'),
                  const SizedBox(height: AppSpacing.md),
                  _HairlineField(
                    label: 'FİRMA NO',
                    controller: _firmaCtrl,
                    hint: 'örn. 126',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _HairlineField(
                    label: 'DÖNEM NO',
                    controller: _donemCtrl,
                    hint: 'örn. 01',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Firma ve dönem numarası giriş sırasında sunucuya gönderilir. '
                    'Boş bırakılırsa sunucudaki varsayılan kullanılır.',
                    style: AppTypography.bodySmall.copyWith(
                      color: _SettingsPalette.textMute,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: _SettingsPalette.accent,
        fontSize: 11,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: const ['monospace'],
      ),
    );
  }

  Widget _buildTestRow() {
    final (Color color, IconData? icon) = switch (_testState) {
      _TestState.success => (_SettingsPalette.accent, Icons.check_circle_outline),
      _TestState.error => (_SettingsPalette.negative, Icons.error_outline),
      _ => (_SettingsPalette.textDim, null),
    };
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _testState == _TestState.loading ? null : _testConnection,
          icon: _testState == _TestState.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _SettingsPalette.accent,
                  ),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: const Text('Bağlantıyı Test Et'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _SettingsPalette.text,
            side: const BorderSide(color: _SettingsPalette.hairline),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (_testMessage != null)
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    _testMessage!,
                    style: AppTypography.bodySmall.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _SettingsPalette.accent,
          foregroundColor: Colors.black,
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
                  color: Colors.black,
                ),
              )
            : Text('Kaydet', style: AppTypography.button),
      ),
    );
  }
}

// ─── Giriş ekranıyla aynı hairline input stili ───
class _HairlineField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _HairlineField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  State<_HairlineField> createState() => _HairlineFieldState();
}

class _HairlineFieldState extends State<_HairlineField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.caption.copyWith(
            color: _SettingsPalette.textDim,
            fontSize: 9.5,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: const ['monospace'],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          cursorColor: _SettingsPalette.accent,
          cursorWidth: 2,
          style: const TextStyle(
            color: _SettingsPalette.text,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 10),
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: _SettingsPalette.textMute,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          height: focused ? 1.5 : 1,
          color: focused ? _SettingsPalette.accent : _SettingsPalette.hairline,
        ),
      ],
    );
  }
}
