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

/// İnce yetki anahtarları — backend `AppPermissions` ile birebir aynı.
/// Effective yetki seti backend'den (login yanıtı) gelir; rol yalnızca
/// varsayılanları belirler (asıl karar backend'de hesaplanır).
class Perm {
  Perm._();

  static const viewReports = 'view_reports';
  static const viewFinancialReports = 'view_financial_reports';
  static const viewStokCost = 'view_stok_cost';
  static const viewDashboardFinancials = 'view_dashboard_financials';
  static const viewPatronPanel = 'view_patron_panel';
  static const createBelge = 'create_belge';
  static const transferBelge = 'transfer_belge';
  static const deleteBelge = 'delete_belge';
  static const manageUsers = 'manage_users';
  static const editSettings = 'edit_settings';

  /// Katalog sırası — admin yetki editörü bu sırayla gösterir.
  static const all = <String>[
    viewReports,
    viewFinancialReports,
    viewStokCost,
    viewDashboardFinancials,
    viewPatronPanel,
    createBelge,
    transferBelge,
    deleteBelge,
    manageUsers,
    editSettings,
  ];

  /// Admin editöründe gösterilen Türkçe etiketler.
  static const labels = <String, String>{
    viewReports: 'Raporlar (şirket raporları)',
    viewFinancialReports: 'Finansal rapor (cari bakiye, vade)',
    viewStokCost: 'Stok maliyet / alış fiyatı',
    viewDashboardFinancials: 'Ana sayfa finansalları',
    viewPatronPanel: 'Patron paneli (nakit, çek-senet, yaşlandırma)',
    createBelge: 'Belge oluştur (fatura/sipariş/irsaliye)',
    transferBelge: "Belgeyi LOGO'ya aktar",
    deleteBelge: 'Belge / taslak sil',
    manageUsers: 'Kullanıcı yönetimi',
    editSettings: 'Sunucu / firma ayarları',
  };

  static String label(String key) => labels[key] ?? key;
}

/// Kullanıcının effective yetki seti (backend'den gelir). UI gizleme/gösterme için.
/// NOT: Yalnızca arayüz kısıtlamasıdır; gerçek sınır backend policy'leridir.
class Permissions {
  final Set<String> _granted;
  const Permissions(this._granted);

  bool has(String key) => _granted.contains(key);

  bool get canViewReports => has(Perm.viewReports);
  bool get canViewFinancialReports => has(Perm.viewFinancialReports);
  bool get canViewStokCost => has(Perm.viewStokCost);
  bool get canViewDashboardFinancials => has(Perm.viewDashboardFinancials);
  bool get canViewPatronPanel => has(Perm.viewPatronPanel);
  bool get canCreateBelge => has(Perm.createBelge);
  bool get canTransferBelge => has(Perm.transferBelge);
  bool get canDeleteBelge => has(Perm.deleteBelge);
  bool get canManageUsers => has(Perm.manageUsers);
  bool get canEditSettings => has(Perm.editSettings);
}
