/// Uygulama rolleri ve rol bazlı yetkiler (RBAC).
///
/// Yetki matrisi TEK kaynak burada — UI bu getter'lara göre gizler/gösterir.
/// NOT: Bu yalnızca arayüz kısıtlamasıdır; gerçek güvenlik sınırı backend'dedir
/// (token doğrulama + [Authorize] rol guard'ları). İstemci gizlemesi UX içindir.
library;

/// Sistemdeki dört rol. Backend `AppUsers.Role` ile eşleşir.
enum AppRole {
  /// Teknik yönetici — her şey + sunucu/firma ayarları.
  admin,

  /// İş sahibi — tüm finansal görünüm + onay + kullanıcı yönetimi.
  patron,

  /// Muhasebe — finansal görünüm, kullanıcı yönetimi yok.
  muhasebe,

  /// Satışçı (saha) — maliyet/kâr ve şirket raporlarını görmez.
  satisci;

  /// Backend'den gelen rol string'ini enum'a çevirir (harf duyarsız).
  /// Bilinmeyen/boş ya da eski "User" rolü → en kısıtlı rol (satisci):
  /// güvenli varsayılan, yanlışlıkla fazla yetki vermez.
  static AppRole fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'admin':
        return AppRole.admin;
      case 'patron':
        return AppRole.patron;
      case 'muhasebe':
        return AppRole.muhasebe;
      case 'satisci':
      case 'satışçı':
      case 'satici':
        return AppRole.satisci;
      default:
        return AppRole.satisci; // bilinmeyen/eski rol = en az yetki
    }
  }

  /// Backend'e/DB'ye yazılan kanonik değer (ASCII — JWT/Authorize uyumu için).
  String get value {
    switch (this) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.patron:
        return 'Patron';
      case AppRole.muhasebe:
        return 'Muhasebe';
      case AppRole.satisci:
        return 'Satisci';
    }
  }

  /// Kullanıcıya gösterilen Türkçe etiket.
  String get label {
    switch (this) {
      case AppRole.admin:
        return 'Yönetici';
      case AppRole.patron:
        return 'Patron';
      case AppRole.muhasebe:
        return 'Muhasebe';
      case AppRole.satisci:
        return 'Satışçı';
    }
  }

  /// Rolün kısa açıklaması (kullanıcı formundaki dropdown için).
  String get aciklama {
    switch (this) {
      case AppRole.admin:
        return 'Tam yetki + sunucu/firma ayarları';
      case AppRole.patron:
        return 'Tüm finansal görünüm, onay ve kullanıcı yönetimi';
      case AppRole.muhasebe:
        return 'Finansal görünüm — kullanıcı yönetimi yok';
      case AppRole.satisci:
        return 'Saha — maliyet, kâr ve şirket raporları gizli';
    }
  }
}

/// Bir role karşılık gelen yetki seti. Matris bu sınıfta yaşar.
class Permissions {
  final AppRole role;
  const Permissions(this.role);

  bool get _isAdmin => role == AppRole.admin;
  bool get _isPatron => role == AppRole.patron;
  bool get _isSatisci => role == AppRole.satisci;

  /// Şirket raporları (Raporlar sekmesi + Ana sayfa rapor kısayolu).
  /// Satışçı şirket geneli raporlarını görmez.
  bool get canViewReports => !_isSatisci;

  /// Finansal raporlar (cari bakiye, vade). Satışçı göremez.
  bool get canViewFinancialReports => !_isSatisci;

  /// Stok maliyet / alış fiyatı görür. Satışçı göremez.
  bool get canViewStokCost => !_isSatisci;

  /// Kâr / marj bilgisi görür. Satışçı göremez.
  bool get canViewProfit => !_isSatisci;

  /// Fatura/sipariş/irsaliye taslağı oluşturabilir. (Tüm roller)
  bool get canCreateBelge => true;

  /// Belge onaylayabilir. Admin + Patron.
  bool get canApprove => _isAdmin || _isPatron;

  /// Kullanıcı yönetimi. Admin + Patron.
  bool get canManageUsers => _isAdmin || _isPatron;

  /// Sunucu/firma ayarlarını uygulama içinden düzenler. Sadece Admin.
  bool get canEditSettings => _isAdmin;
}
