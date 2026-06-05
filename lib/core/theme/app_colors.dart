import 'package:flutter/material.dart';

/// Uygulamanın renk paleti.
/// Renk eklerken/değiştirirken burayı kullan, asla doğrudan Color(0xFF...) yazma.
class AppColors {
  // ── Primary: Lacivert (kurumsal, güven) ──
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF334155);

  // ── Accent: Teal (modern, pozitif vurgu) ──
  static const Color accent = Color(0xFF14B8A6);
  static const Color accentLight = Color(0xFF5EEAD4);
  static const Color accentDark = Color(0xFF0F766E);

  // ── Semantik renkler ──
  static const Color positive = Color(0xFF15803D);       // Alacak, başarı
  static const Color positiveBg = Color(0xFFDCFCE7);
  static const Color negative = Color(0xFFB91C1C);       // Borç, hata, vade geçen
  static const Color negativeBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFB45309);        // Vadesi yaklaşan
  static const Color warningBg = Color(0xFFFEF3C7);

  // ── Nötr (slate skalası) ──
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ── Yüzeyler ──
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Yön B: Premium Energetic ──
  static const Color violetDark = Color(0xFF1E1B4B);
  static const Color violetMid = Color(0xFF312E81);
  static const Color violet = Color(0xFF4C1D95);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFF472B6);
  static const Color pinkLight = Color(0xFFF9A8D4);

  static const Color liveGreen = Color(0xFF4ADE80);
}