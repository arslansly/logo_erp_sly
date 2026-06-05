import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../cari/cari_model.dart';
import '../cari/cari_service.dart';
import '../fatura/fatura_form_screen.dart';
import '../siparis/siparis_form_screen.dart';
import 'ai_model.dart';
import 'ai_service.dart';

/// Yapay zeka asistanı sohbet ekranı.
/// Kullanıcı doğal dille yazar; asistan bilgi getirir ya da fatura/sipariş
/// formunu ön-dolu açacak bir aksiyon önerir.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _isSending = false;

  // Sesli giriş (speech-to-text)
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _onceListenMetin = ''; // dinleme başlarken kutudaki metin

  // Boş ekranda gösterilen örnek komutlar.
  static const _ornekler = [
    'Doğrunet\'in bakiyesi nedir?',
    'Bugünkü tahsilatlar ne kadar?',
    'Çimento stoğu kaç?',
    'Doğrunet\'e 5 adet çimento sat',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onStatus: (s) {
          // Dinleme bittiğinde (done/notListening) butonu sıfırla.
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() => _speechReady = ok);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  Future<void> _toggleDinle() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon kullanılamıyor (izin gerekebilir)')),
          );
        }
        return;
      }
    }
    _onceListenMetin = _controller.text;
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: 'tr_TR', cancelOnError: true),
      onResult: (r) {
        final prefix = _onceListenMetin.isEmpty ? '' : '$_onceListenMetin ';
        _controller.text = prefix + r.recognizedWords;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    // Mevcut mesaj eklenmeden ÖNCEKİ geçmişi backend'e gönder.
    final history = List<AiMessage>.from(_messages);

    setState(() {
      _messages.add(AiMessage(role: 'user', text: text));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final resp = await aiService.chat(text, history);
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(
          role: 'assistant',
          text: resp.reply.isEmpty ? '(boş cevap)' : resp.reply,
          action: resp.action,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(role: 'assistant', text: '$e'));
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  // Aksiyonu uygula → tam cari nesnesini çekip ilgili formu ön-dolu aç.
  Future<void> _openAction(AiAction action) async {
    if (action.cari == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Cari cari;
    try {
      cari = await cariService.getCariById(action.cari!.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: AppColors.negative, content: Text('Cari açılamadı: $e')),
      );
      return;
    }
    if (!mounted) return;

    if (action.isFatura) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaturaFormScreen(
            onceSecilenCari: cari,
            onceSecilenSatirlar: action.lines,
            onceSecilenTrCode: action.trCode,
          ),
        ),
      );
    } else if (action.isSiparis) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SiparisFormScreen(
            onceSecilenCari: cari,
            onceSecilenSatirlar: action.lines,
            vade: action.vade,
            onceSecilenTrCode: action.trCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.slate800 : AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.violet],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Yapay Zeka Asistanı',
                style: AppTypography.h2.copyWith(
                    color: isDark ? Colors.white : AppColors.slate900)),
          ],
        ),
        foregroundColor: isDark ? Colors.white : AppColors.slate900,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _messages.length) return _buildTyping(isDark);
                      return _buildMessage(_messages[i], isDark);
                    },
                  ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  // ─── Boş durum ───
  Widget _buildEmptyState(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.accent, AppColors.violet]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Size nasıl yardımcı olabilirim?',
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(
                color: isDark ? Colors.white : AppColors.slate900)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Cari bakiyesi sorun, stok öğrenin ya da fatura/sipariş hazırlatın.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.slate400 : AppColors.slate500),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._ornekler.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OrnekKomut(
                metin: o,
                isDark: isDark,
                onTap: () => _send(o),
              ),
            )),
      ],
    );
  }

  // ─── Mesaj balonu ───
  Widget _buildMessage(AiMessage m, bool isDark) {
    final isUser = m.isUser;
    final bubbleColor = isUser
        ? AppColors.accent
        : (isDark ? AppColors.slate800 : AppColors.surface);
    final textColor = isUser
        ? Colors.white
        : (isDark ? AppColors.slate100 : AppColors.slate800);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              boxShadow: isUser
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(m.text,
                style: AppTypography.body.copyWith(color: textColor)),
          ),
          if (m.action != null && m.action!.isUygulanabilir)
            _buildActionCard(m.action!, isDark),
        ],
      ),
    );
  }

  // ─── Aksiyon kartı (fatura/sipariş aç) ───
  Widget _buildActionCard(AiAction action, bool isDark) {
    final alis = action.isSatinalma;
    final renk = alis ? AppColors.cyan : AppColors.positive;
    final belge = action.isFatura ? 'Fatura' : 'Sipariş';
    final baslik = '${alis ? 'Satınalma' : 'Satış'} $belge';
    final ikon = action.isFatura
        ? Icons.receipt_long_rounded
        : Icons.shopping_cart_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(ikon, size: 18, color: renk),
                const SizedBox(width: AppSpacing.sm),
                Text(baslik, style: AppTypography.h3.copyWith(color: renk)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.cari!.unvan,
                    style: AppTypography.h3.copyWith(
                        color: isDark ? AppColors.slate100 : AppColors.slate800)),
                Text(action.cari!.kod,
                    style: AppTypography.caption),
                if (action.lines.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ...action.lines.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${l.ad}  ×${_fmtMiktar(l.miktar)}'
                          '${l.fiyat != null ? ' @ ${_fmtMiktar(l.fiyat!)}' : ''}',
                          style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate600),
                        ),
                      )),
                ],
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openAction(action),
                    style: FilledButton.styleFrom(backgroundColor: renk),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(action.isFatura ? 'Faturayı Aç' : 'Siparişi Aç'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── "Yazıyor..." göstergesi ───
  Widget _buildTyping(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 36,
          child: _TypingDots(),
        ),
      ),
    );
  }

  // ─── Giriş çubuğu ───
  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white : AppColors.slate900),
              decoration: InputDecoration(
                hintText: _isListening ? 'Dinliyorum…' : 'Bir şey yazın…',
                hintStyle: AppTypography.body.copyWith(
                    color: _isListening ? AppColors.negative : AppColors.slate400),
                filled: true,
                fillColor: isDark ? AppColors.slate900 : AppColors.slate100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                suffixIcon: _speechReady
                    ? IconButton(
                        onPressed: _toggleDinle,
                        icon: Icon(
                          _isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                          color: _isListening ? AppColors.negative : AppColors.accent,
                        ),
                        tooltip: _isListening ? 'Durdur' : 'Sesli komut',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SendButton(enabled: !_isSending, onTap: _send),
        ],
      ),
    );
  }

  String _fmtMiktar(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

// ─── Örnek komut çipi ───
class _OrnekKomut extends StatelessWidget {
  final String metin;
  final bool isDark;
  final VoidCallback onTap;
  const _OrnekKomut({required this.metin, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.slate700 : AppColors.slate200),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(metin,
                  style: AppTypography.body.copyWith(
                      color: isDark ? AppColors.slate100 : AppColors.slate700)),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}

// ─── Gönder butonu ───
class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(colors: [AppColors.accent, AppColors.accentDark])
              : null,
          color: enabled ? null : AppColors.slate300,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
      ),
    );
  }
}

// ─── Animasyonlu "yazıyor" noktaları ───
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_c.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.slate400,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
