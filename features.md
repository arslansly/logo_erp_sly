# logo_mobil — Özellik Durumu

Son güncelleme: 2026-06-07 (Rol bazlı yetki sistemi — RBAC, Blok ①)

## En son ne yapıldı (2026-06-07 — Rol bazlı yetki sistemi / RBAC, Blok ①)

Ürünleştirme stratejisi netleşti: program patronlara **"bitmiş ürün"** gibi gösterilecek; altyapı/yayınlama/güvenlik (hosting, lisans vb.) satış kararına bırakıldı. İlk blok **yetki sistemi**. Roller artık `Admin`/`User` yerine **4 hazır rol**: Admin (Yönetici), Patron, Muhasebe, Satışçı — her birinin sabit yetki seti. Kapsam AskUserQuestion ile netleşti (hazır roller; ilk blok = yetki).

**Yetki matrisi (özet):**
- **Satışçı** — şirket raporları yok, stok **maliyet**/kâr yok, kullanıcı yönetimi yok (belge oluşturabilir).
- **Muhasebe** — finansal görünüm var, kullanıcı yönetimi yok.
- **Patron** — tüm finansal + onay + kullanıcı yönetimi (sunucu/firma ayarı yok).
- **Admin** — her şey + ayarlar.

**Frontend (`logo_mobil`)** — YENİ `lib/core/auth/app_role.dart`: `AppRole` enum (admin/patron/muhasebe/satisci) + `Permissions` sınıfı (**tek doğruluk kaynağı**: `canViewReports`, `canViewFinancialReports`, `canViewStokCost`, `canViewProfit`, `canCreateBelge`, `canApprove`, `canManageUsers`, `canEditSettings`). `AppRole.fromString` bilinmeyen/eski "User" → satisci (en az yetki, güvenli varsayılan).
- `auth_service.dart` — senkron rol önbelleği (`role`/`perms`); login'de doldurulur, logout'ta temizlenir, boot'ta `loadRole()` (`main.dart`). Mevcut `isAdmin()` korundu.
- `main_shell.dart` — alt sekmeler yetkiye göre **dinamik**; Satışçı'da **Raporlar sekmesi gizli** (sabit 6 sekme → filtreli liste, IndexedStack uyumlu).
- `dashboard_screen.dart` — Raporlar kısayol kartı `canViewReports`'a bağlı.
- `profil_screen.dart` — "Kullanıcı Yönetimi" girişi `canManageUsers`'a bağlı (eski `isAdmin` yerine); kullanıcı kartında **rol etiketi** gösterilir.
- `malzeme_detay_screen.dart` — "Fiyatlar" bölümünde **satınalma + son alış (maliyet)** Satışçı'ya gizli, **satış** fiyatları herkese açık (fiyat bölümü liste tabanlı yeniden kuruldu; divider düzeni korundu, boş bölüm oluşmaz).
- `user_form_screen.dart` — rol dropdown'ı 2 değer → **4 rol** + seçili rolün açıklaması; yeni kullanıcı varsayılanı Satışçı (en az yetki).
- `user_list_screen.dart` — rol rozeti 4 role göre etiket/renk (artık sadece Admin için değil).
- **Not:** `canCreateBelge` 4 rolde de `true` olduğu için belge FAB'larına koşul eklenmedi (ölü koddan kaçınıldı); yetki noktası `Permissions`'ta hazır, kısıtlı rol gelince tek satırla bağlanır.

**Backend (`LogoMobileApi`)** — YENİ `Services/RoleHelper.cs`: kanonik roller (Admin/Patron/Muhasebe/Satisci, Flutter ile ASCII eşli) + `Normalize` (geçersiz/eski rol → Satisci).
- `Services/AuthService.cs` — create/update'te rol `RoleHelper.Normalize` ile doğrulanır (create varsayılanı da Satisci).
- `Controllers/UsersController.cs` — `[Authorize(Roles="Admin,Patron")]`.
- `Controllers/RaporController.cs` — finansal uçlar (`cari-bakiye`, `vade`) `[Authorize(Roles="Admin,Patron,Muhasebe")]` (Satışçı 403); stok raporları tüm rollere açık.
- JWT zaten `ClaimTypes.Role` gömüyor; şifreler BCrypt.
- **Bilinen (M-Güvenlik'e bırakıldı):** `MalzemeController` detayında maliyet alanlarını Satışçı için backend'de maskeleme henüz yok (UI gizliyor); tam alan-bazlı maskeleme güvenlik fazında.

**Doğrulama:** `flutter analyze` (9 değişen dosya) → **0 issue**. Backend `dotnet build` → **0 uyarı / 0 hata**.

**Test adımları:**
1. **Backend restart** (UsersController/RaporController guard + RoleHelper). Mevcut "User" rollü kullanıcılar artık Satışçı yetkisinde görünür.
2. Admin ile gir → Profil > Kullanıcı Yönetimi → her rolden birer kullanıcı oluştur (rol dropdown 4 değer + açıklama).
3. **Satışçı** ile gir → alt barda **Raporlar yok**, Ana sayfada rapor kartı yok, Profil'de Kullanıcı Yönetimi yok, stok detayında maliyet/son alış yok (satış fiyatı var).
4. **Muhasebe** → Raporlar var (finansal dahil), Kullanıcı Yönetimi yok.
5. **Patron** → her şey + Kullanıcı Yönetimi. **Admin** → + ayarlar.
6. Backend: Satışçı token'ıyla `/api/users` → **403**; `/api/rapor/cari-bakiye` ve `/vade` → **403**; `/api/rapor/stok` → 200.

> Demo anlatısı: aynı cihazda Satışçı → çıkış → Patron girişi ile uygulamanın **kılık değiştirmesi** — "rol bazlı, kurumsal" hissini tek hamlede verir.

**Sıradaki bloklar:** ② Patron paneli (gerçek nakit/alacak-borç/çek-senet + sahte trend temizliği), ③ Satışçı saha, ④ Raporlar genişletme, ⑤ Demo cilası; **en son** (satış kararından sonra) altyapı & güvenlik.

---

Son güncelleme: 2026-06-03 (Yapay zeka asistanı — doğal dil komutları)

## En son ne yapıldı (2026-06-03 — Yapay zeka asistanı, Faz 1)

Ana sayfaya **yapay zeka asistanı** eklendi. Kullanıcı doğal dille (Türkçe) yazıyor; asistan ya bilgi getiriyor (cari bakiye, stok, dashboard özeti) ya da **fatura/sipariş formunu ön-dolu açacak** bir aksiyon öneriyor. Örnek: "Doğrunet'e 5 adet çimento sat" → cari + kalem + miktar çözülür, satış faturası formu ön-dolu açılır; kullanıcı görür, düzeltir, kaydeder. **AI asla doğrudan kayıt oluşturmaz** — güvenlik için form onayı şart.

**Mimari kararlar (varsayılan):** Model = **Claude (Anthropic)** tool-use; çağrı **backend üzerinden** (`/api/ai/chat`) → API anahtarı sunucuda gizli, mevcut LOGO servislerine bağlanır; aksiyon = **form ön-doldur + kullanıcı onayı**; arayüz = **tam sohbet ekranı** (sesli giriş sonraki faza).

**Backend (`LogoMobileApi`)** — YENİ:
- `Services/AiService.cs` — Anthropic Messages API'sini düz `HttpClient` ile çağırır (resmi SDK yok). Tool-use döngüsü (maks. 6 tur, sonsuz döngü koruması). 8 tool: `cari_ara`, `cari_bakiye`, `malzeme_ara`, `malzeme_detay`, `stok_durumu`, `dashboard_ozet` (okuma — mevcut servisleri çağırır) + `fatura_hazirla`, `siparis_hazirla` (**yan etkisiz** — cari/kalemleri çözüp `AiAction` döner, kayıt YOK). Türkçe sistem promptu.
- `Models/AiDtos.cs` — `AiChatRequest`/`AiChatResponse`/`AiAction`/`AiCariRef`/`AiLine`.
- `Controllers/AiController.cs` — `[Authorize] POST /api/ai/chat`.
- `Program.cs` — `AddHttpClient<AiService>()`. `appsettings.json` — `AiSettings { ApiKey, Model, MaxTokens }` (anahtar BOŞ; `dotnet user-secrets`/ortam değişkeni ile verilir, repoya yazılmaz). Model varsayılan `claude-sonnet-4-6`.
- Tüm tool'lar mevcut `FirmaContext` (JWT firma/dönem) ile çalışır — ek iş yok.

**Frontend (`logo_mobil`)** — YENİ `lib/features/ai/`:
- `ai_model.dart` — `AiMessage`/`AiChatResponse`/`AiAction`/`AiCariRef`/`AiLineSeed` (backend DTO eşli, camelCase).
- `ai_service.dart` — `aiService` singleton (`/api/Ai/chat`, cari_service kalıbı `_handleError`).
- `ai_chat_screen.dart` — sohbet ekranı: mesaj balonları, boş durum (örnek komut çipleri), animasyonlu "yazıyor" göstergesi, dark mode, `AppColors`/`AppTypography`/`AppSpacing`. Asistan cevabında aksiyon varsa **aksiyon kartı** (cari + satır özeti + "Faturayı/Siparişi Aç" butonu) → tam `Cari` çekilip ilgili form ön-dolu açılır.

**Frontend — güncellenen:**
- `fatura_form_screen.dart` + `siparis_form_screen.dart` — yeni opsiyonel `onceSecilenSatirlar` (+ siparişte `vade`) parametresi. `initState`'te AI tohum satırları forma eklenir (`_seedAiLines`/`_hydrateSeedLine`: malzeme detayı arka planda çekilir, fiyat boşsa tanımlı satış fiyatı konur). Satır geldiğinde tür otomatik **Toptan Satış / Satış Siparişi** seçilir (tür seçim ekranı atlanır). Mevcut davranış geri uyumlu — parametre verilmezse hiçbir değişiklik yok.
- `dashboard_screen.dart` — header'a (bildirim zilinin soluna) teal→mor gradyanlı **AI butonu** (`Icons.auto_awesome`) → `AiChatScreen`.

**Doğrulama:** Backend `dotnet build` → C# derlemesi başarılı (çalışan API exe'si kilitliydi, sadece copy hatası; 0 derleme hatası). `flutter analyze` (ai + değişen formlar + dashboard) → **0 issue**.

**Test adımları:**
1. **API anahtarı:** `dotnet user-secrets set "AiSettings:ApiKey" "sk-ant-..."` (LogoMobileApi klasöründe) ya da `AiSettings__ApiKey` ortam değişkeni. **Backend restart** (yeni AiController + AiService).
2. **Backend dumanı (Swagger/curl):** JWT'li `POST /api/ai/chat` → "merhaba" düz cevap; "Doğrunet bakiyesi" → `cari_ara`+`cari_bakiye`, doğru rakam; "çimento stok kaç" → `stok_durumu`; "Doğrunet'e 5 adet çimento sat 100 TL" → `action.type=fatura` + cari + lines döner, **DB'de yeni draft OLUŞMAZ** (kontrol et).
3. **Flutter:** Ana sayfa → sağ üst AI butonu → örnek komut çipleri çalışıyor mu? Bakiye/stok sorularına metin cevap. "…sat/…fatura kes" → aksiyon kartı → "Faturayı Aç" → form cari + kalem + fiyat dolu geliyor mu? "Kaydet" ile normal taslak akışı çalışıyor mu?
4. Çok adımlı: birden fazla "Doğrunet" varsa asistan "hangisi?" diye sormalı.

**Sıradaki turlar:** maliyet için tool turu/limit ayarı, toptan/perakende ayrımı. **Not:** asistanın "fatura kes" akışı taslak oluşturmaya kadar gider; LOGO'ya gerçek aktarım hâlâ stub (önceki turlarla aynı).

### Ekler (aynı tur — tür seçimi + sesli giriş)

**1. Belge türü (satış/satınalma) artık asistan tarafından belirleniyor.** Eskiden "fatura kes" hep Toptan Satış'a gidiyordu; artık asistan cümleden türü çıkarır, **belirsizse sorar.**
- Backend: `fatura_hazirla`/`siparis_hazirla` tool'larına `tip` ("satis"/"satinalma") parametresi; `AiAction.TrCode` eklendi (fatura: 38 satış / 31 satınalma · sipariş: 1 satış / 2 satınalma). Sistem promptuna kural 3: "sat/satış/fatura kes → satış; al/alış/satınalma → satınalma; **belirsizse aracı çağırmadan önce SOR**".
- Flutter: `AiAction.trCode` + `isSatinalma` getter. `fatura_form_screen`/`siparis_form_screen` yeni `onceSecilenTrCode` parametresi → `_tur = FaturaTuru/SiparisTuru.fromTrCode(...)` (yoksa eski varsayılan). Aksiyon kartı başlığı artık "Satış/Satınalma Fatura/Sipariş" (renk: satınalma = cyan, satış = yeşil). Satınalmada satır fiyatı tanımlı **alış** fiyatından gelir (mevcut `_hydrateSeedLine` `kategori` mantığı).

**2. Sesli giriş (speech-to-text).** Sohbet kutusunda mikrofon ikonu → Türkçe (`tr_TR`) sesli komut; tanınan metin kutuya yazılır, kullanıcı görüp gönderir.
- Paket `speech_to_text: ^7.0.0`. `ai_chat_screen`: `_initSpeech`/`_toggleDinle`, dinlerken kırmızı "Durdur" ikonu + "Dinliyorum…" hint. İzin yoksa snackbar uyarısı.
- Android `AndroidManifest.xml`: `RECORD_AUDIO` izni + `RecognitionService` queries. iOS `Info.plist`: `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`.

**Doğrulama (ekler):** Backend `dotnet build` (ayrı `bin/Verify`, sonra silindi) → **0 uyarı/0 hata**. `flutter analyze` → **0 issue**. `flutter pub get` → speech_to_text kuruldu.

> ⚠️ Sesli giriş paket eklediği için **hot reload yetmez** — uygulamayı tam kapatıp yeniden çalıştırın (gerekirse `flutter clean`). İlk mikrofon kullanımında izin sorulur. Emülatörde mikrofon olmayabilir; gerçek cihazda test edin.

---

Son güncelleme: 2026-06-02 (Raporlar alanı — çekirdek 5 rapor)

## En son ne yapıldı (2026-06-02 — Raporlar alanı, çekirdek set)

Merkezi bir **Raporlar** alanı eklendi: tek bir hub'tan filtrelenebilir ve **PDF olarak paylaşılabilir** raporlar. Kapsam **AskUserQuestion** ile netleştirildi (erişim = hem 6. alt sekme hem Ana sayfa kısayolu; her raporda PDF; bu tur = çekirdek 5 rapor). Sonraki tur: fatura/irsaliye/sipariş raporları.

**Raporlar (çekirdek 5):**
1. **Cari bakiye raporu** — kod, ünvan, şehir/ülke, telefon, borç/alacak/bakiye. Filtre: arama, cari türü (Alıcı/Satıcı), bakiye durumu (Borçlu/Alacaklı).
2. **Vade raporu** — vadesi geçen cariler + yaşlandırma kovaları (0-30/31-60/61-90/90+). Filtre: min gecikme (30/60/90 gün). Üstte toplam özet barı.
3. **Stok durum raporu** — ad/açıklama (NAME2), birim, tür, fiili/gerçek stok. Filtre: arama, tür (MalzemeTur), stok durumu (var/yok).
4. **Ayrıntılı stok raporu** — malzeme bazında ambar dökümü (ExpansionTile; ambar adı `L_CAPIWHOUSE`'tan dinamik).
5. **Kritik stok raporu** — fiili stoğu asgari (INVDEF.MINLEVEL) altındaki malzemeler; fark vurgusu.

**Backend (`LogoMobileApi`)** — `Controllers/RaporController.cs` YENİ (`/api/Rapor`: `cari-bakiye`, `vade`, `stok`, `stok-ambar`, `kritik-stok`). `Services/RaporService.cs` YENİ (Dapper + `FirmaContext` + `WITH(NOLOCK)`, mevcut Cari/Malzeme/Dashboard kalıbı). `Models/` YENİ: `CariBakiyeRapor`, `VadeRapor`, `StokRapor`, `StokAmbarRapor`, `KritikStokRapor` (`AmbarStok` reuse). `Program.cs`: `AddScoped<RaporService>()`. SQL kuralları `LOGO_ERP_DATABASE_REFERENCE.md` esas (cari bakiye=GNTOTCL TOTTYP=1; vade=PAYTRANS aging; stok=STINVTOT SUM+GROUP BY; kritik=Şablon D, MINLEVELCTRL'e güvenilmez).

**Frontend (`logo_mobil`)** — `lib/features/rapor/` YENİ: `rapor_model.dart` (5 model, JSON camelCase backend ile eşli), `rapor_service.dart` (`raporService`, cari_service kalıbı), `rapor_widgets.dart` (ortak RaporLoading/Error/Empty/SearchBar/Chip), `rapor_hub_screen.dart` + 5 rapor ekranı. PDF: `pdf_exporter.dart`'a genel `buildTabloRaporPdf` (başlık + özet kartları + tablo); önizleme/paylaşma için mevcut `PdfOnizlemeScreen` reuse.

**Navigasyon:** `main_shell.dart` → 6. alt sekme "Raporlar" (`Icons.bar_chart_rounded`; etiketler kısaltıldı: "Ana"). `dashboard_screen.dart` → KPI/hızlı işlemler altına teal gradyanlı "Raporlar" kısayol kartı (`RaporHubScreen`'e push). İkisi de aynı hub'a gider.

**Doğrulama:** Backend `dotnet build` → derleme başarılı (çalışan API exe'si kilitliydi, sadece copy hatası; 0 derleme hatası). `flutter analyze` → yeni rapor dosyalarında 0 issue (kalan 12 uyarı login_screen/user_list_screen, dokunulmadı).

**Test adımları:**
1. **Backend restart** (yeni RaporController). Swagger'da `/api/Rapor/cari-bakiye?bakiyeDurumu=borclu`, `/vade?minGun=30`, `/stok?stokDurumu=var`, `/stok-ambar`, `/kritik-stok` token'la 200 dönüyor mu?
2. Alt sekme "Raporlar" + Ana sayfa kısayol kartı → ikisi de hub'ı açıyor.
3. Her raporda: arama/filtre çipleri listeyi daraltıyor; boş/hata/shimmer durumları çalışıyor.
4. Her raporda sağ üst PDF ikonu → önizleme açılıyor, paylaş/yazdır çalışıyor (Türkçe karakterler düzgün).

---

Son güncelleme: 2026-06-02 (uygulama içi konfigürasyon: sunucu adresi + firma/dönem + kullanıcı yönetimi)

## En son ne yapıldı (2026-06-02 — uygulama içi konfigürasyon turu)

Şimdiye dek elle kodlanan ayarlar (sunucu adresi `api_client.dart`'ta hardcoded, firma/dönem backend `appsettings.json`'da) artık **uygulama içinden** yönetiliyor. Kapsam **AskUserQuestion** ile netleştirildi: sunucu = tek düzenlenebilir adres; firma/dönem = ayarlardan bir kez girilir, login'de gönderilip JWT claim'ine gömülür; kullanıcı yönetimi = giriş sonrası, **sadece Admin**.

**1. Giriş ekranı → Ayarlar (sunucu + firma/dönem).** Login ekranı header'ına ⚙ ayarlar butonu (token gerekmez).
- Flutter `lib/features/settings/` YENİ: `settings_model.dart` (`AppConfig`), `settings_service.dart` (`settingsService` — secure storage `server_url`/`firma_no`/`donem_no`, `applyServerUrl`, `testConnection`), `settings_screen.dart` (giriş ekranıyla aynı koyu editorial dil; URL + firma + dönem alanları, **"Bağlantıyı Test Et"** → `/api/health`, Kaydet).
- `core/api/api_client.dart`: `baseUrl` sabiti → `defaultBaseUrl` + yeni `updateBaseUrl()` (Dio adresini runtime'da değiştirir). `main.dart` başlangıçta `settingsService.applyServerUrl()`.
- `auth_model.dart` `LoginRequest`: opsiyonel `firmaNo`/`donemNo`. `auth_service.login` ayarlardan firma/dönem'i okuyup gönderir; login'de `user_role` saklanır (`getUserRole`/`isAdmin`). `logout()` artık sunucu/firma ayar anahtarlarını **silmiyor** (last_username gibi korunuyor).

**2. Backend — firma/dönem JWT claim'inden (servis refactor).** Firma/dönem artık istek bazlı, kullanıcının seçimine göre.
- `Models/LoginRequest.cs`: `FirmaNo`/`DonemNo`. `Services/JwtTokenService.cs`: token'a `firmaNo`/`donemNo` claim'leri (boş/geçersizse appsettings default). `Services/AuthService.cs` + `Controllers/AuthController.cs`: firma/dönem login'den token'a akar.
- `Services/FirmaContext.cs` YENİ (scoped): firma/dönem'i JWT claim'inden okur, yoksa config default'a düşer. **GÜVENLİK:** değerler SQL'e tablo adı olarak gömüldüğü için (`LG_{firma}_...`) yalnızca **rakam** kabul edilir (digit-only regex), aksi halde default. `Program.cs`: `AddHttpContextAccessor` + `AddScoped<FirmaContext>`.
- 7 Logo servisi (`Cari`, `Dashboard`, `Malzeme`, `Fatura`, `Siparis`, `Irsaliye`, `Lookup`) constructor'da `IConfiguration` firma/dönem yerine `FirmaContext` enjekte ediyor; SQL string'leri değişmedi. Draft servisleri (kendi tablolarını kullanır) dokunulmadı.

**3. Kullanıcı yönetimi (Admin CRUD).** Profil ekranında sadece Admin rolüne görünen "Kullanıcı Yönetimi" girişi.
- Backend `Controllers/UsersController.cs` YENİ — `[Authorize(Roles="Admin")]`: GET/POST/PUT/DELETE `/api/users`. `AuthService`'e `ListUsersAsync`/`UpdateUserAsync`/`DeleteUserAsync` (Dapper; PasswordHash dışarı verilmez; şifre boşsa değişmez; admin kendini silemez). `Models/UserDtos.cs` YENİ (`UserListItem`/`CreateUserRequest`/`UpdateUserRequest`). `Controllers/HealthController.cs` YENİ (anonim `/api/health`).
- Flutter `lib/features/users/` YENİ: `user_model.dart` (`AppUser`), `user_service.dart` (`/api/users` CRUD), `user_list_screen.dart` (skeleton + empty/error state, FAB, sil onayı, rol rozeti), `user_form_screen.dart` (ekle/düzenle; username edit'te kilitli; rol dropdown; aktif switch; şifre edit'te opsiyonel). `profil_screen.dart`: `isAdmin` ise `_AdminSection`.

**Doğrulama:** `dotnet build` → **0 Hata** (ayrı çıktı klasöründe; çalışan API'nin exe'si kilitliydi). `flutter analyze` → yeni dosyalarda 0 hata (kalan uyarılar login_screen.dart'tan, dokunulmadı).

**Test adımları:**
1. **Backend yeniden derlenip restart** edilmeli (firma claim + UsersController + health). Swagger'da `/api/health` (anonim) 200; `/api/users` token'sız 401, Admin token'la 200, `User` rolüyle 403.
2. Giriş ekranı → ⚙ → yanlış URL gir → "Bağlantıyı Test Et" başarısız; doğru URL + firma/dönem kaydet.
3. `admin`/`admin123` ile giriş → Profil'de "Kullanıcı Yönetimi" görünür → ekle/düzenle/sil çalışır. `User` rollü kullanıcıyla giriş → menü gizli.
4. Farklı firma no girip giriş yap → dashboard/cari verisi o firmadan gelir; firma boşsa appsettings default kullanılır.

---

## En son ne yapıldı (2026-06-02 — cihaz testi geri bildirim turu)

Kullanıcının cihaz testinden gelen 5 maddelik geri bildirim uygulandı. Kapsam **AskUserQuestion** ile önden netleştirildi (fatura filtre kategori bazlı; kısmi sevk etiketi "Sevkediliyor"; stok varsayılan = sadece stoğu olanlar).

**1. Faturalar — kategori filtresi.** Aktarılan sekmesine yatay chip'ler eklendi: Hepsi / Satış / Alış / İade.
- Backend `FaturaService.GetAllAsync` + `FaturaController`: yeni `kategori` parametresi (`Satış`=TRCODE 7,8,9 · `Satınalma`=1,4 · `İade`=2,3,6). Dapper aynı parametreyi hem `IN` hem skaler kullanamadığı için `kategoriClause` koşullu enjekte ediliyor.
- Flutter `fatura_service.getFaturalar` `kategori` param; `fatura_list_screen` `_kategoriFilter` + `_buildFilters` (sadece Aktarılan sekmesi).

**2. Sipariş — sevk durumu satırdan türetiliyor (statü düzeltmesi).** Eskiden `ORFICHE.STATUS=4` "Sevkedildi" gösteriliyordu; bu kurulumda 4 = **Sevkedilebilir**. Sevk/teslim durumu artık satır miktarlarından türetilir:
- Backend `SiparisService` GetAll/GetById: ORFLINE aggregate join → `ToplamMiktar`, `SevkMiktar`, `BekleyenMiktar` (kapanış-duyarlı: `CLOSED=1` satır tamamı sevkedilmiş sayılır). `Models/Siparis.cs`'e bu 3 alan eklendi.
- Flutter `siparis_model`: `SiparisDurumu` artık {Öneri(1), Sevkedilemez(2), Sevkedilebilir(4)} (fromKod 3↔4'ü Sevkedilebilir'e eşler). Yeni `SiparisSevkDurumu` {ham, sevkediliyor, sevkedildi}. `SiparisModel`'e `toplamMiktar/sevkMiktar/bekleyenMiktar` + `durumEtiketi/durumRenk/durumIkon` getter'ları. `SiparisSatirModel`: `etkinSevk` (kapalı→amount), `bekleyenMiktar` (kapalı→0), `sevkOrani` kapanış-duyarlı.
- **Detay miktar hatası giderildi:** kapalı satırda bekleyen 0; sevk kolonu `etkinSevk`; özet kart kapanış-duyarlı. Liste kartı türetilmiş rozet + "%N sevk" göstergesi.

**3. Faturalar — PDF & Paylaş kaldırıldı.** `fatura_detay_screen`: AppBar paylaş ikonu + LOGO faturası aksiyon barı (PDF/Paylaş) silindi. `_pdfData`/`_pdfStub` ve `belge_pdf`/`belge_onizleme_screen` import'ları kaldırıldı. (Taslak Düzenle/Aktar barı duruyor.)

**4. Stok — varsayılan davranış + tür filtresi.** Varsayılan ilk açılış artık **sadece stoğu olanlar**. "Stoğu olmayanlar" çipi sadece stok 0 olanları getirir. Ayrıca **tür** filtresi (Hammadde/Yarı Mamul/Mamul/Ticari Mal).
- Backend `MalzemeService.GetAllAsync` + `MalzemeController`: `stokYok` (bool) → `stokDurumu` (`var`/`yok`/null) + yeni `tur` (CARDTYPE) param. Liste `Tur` CASE genişletildi.
- Flutter `malzeme_service.getMalzemeler`: `stokDurumu`+`tur`; `malzeme_model`'e `MalzemeTur` enum. `malzeme_list_screen`: `_stokDurumu` getter (seçim modunda varsayılan tümü), `_turFilter`, yenilenen `_buildFilters` (toggle + tür chip'leri). Malzeme seçici (selectionMode) varsayılan tümünü gösterir.

**5. Dashboard.** Bildirim zili → **son işlem** bottom sheet (en güncel hareket + "Tüm hareketler"). SY avatarı → **hesap menüsü** bottom sheet ("Çıkış Yap"). "Tümü" → yeni `SonHareketlerScreen` (limit 100, `SonHareketRow` paylaşılan widget). Backend değişikliği yok (`/api/Dashboard/son-hareketler` zaten `limit` alıyor).

**Doğrulama:** `dotnet build` → 0 warning/0 error. `flutter analyze` → değişen dosyalarda 0 issue (kalan 9 uyarı login_screen.dart, dokunulmadı).

**Test adımları:**
1. Backend restart. Faturalar → Aktarılan → Satış/Alış/İade chip'leri liste daraltıyor mu?
2. Siparişler → Logo → tamamı kapanmış sipariş "Sevkedildi", yarısı gönderilmiş "Sevkediliyor + %N sevk", hiç gönderilmemiş ham durum (Öneri/Sevkedilemez/Sevkedilebilir). Detayda kapalı satır bekleyen=0 ve sevk=miktar.
3. Fatura detay → PDF/Paylaş butonları yok.
4. Stok → ilk açılış stok 0 gizli; "Stoğu olmayanlar" → sadece 0 olanlar; tür chip'i ile daralt.
5. Ana sayfa → zil → son işlem sheet; avatar → çıkış; "Tümü" → son hareketler listesi.

---

Son güncelleme: 2026-06-01 (PDF offline font düzeltmesi — ekstre önizleme donması)

## En son ne yapıldı (2026-06-01 — Faz 2: sipariş + irsaliye taslak yazma)

Faz 1'de okuma katmanı (liste + detay) tamamlanan sipariş ve irsaliyeye, fatura taslak akışıyla **birebir paralel** bir taslak yazma katmanı eklendi. Mobil kullanıcı artık sipariş/irsaliye taslağı oluşturup düzenleyebilir, siler ve "Kaydet ve Aktar" diyebilir. LOGO'ya gerçek aktarım hâlâ **stub** (fatura ile aynı): taslak `Failed` olur, hata mesajı Hatalı sekmesinde görünür. Zincir akışlar (siparişten irsaliye / irsaliyeden fatura) Faz 3'te.

**Karar matrisi** (kullanıcı ile, 2026-06-01):

| Soru | Karar |
|---|---|
| Sipariş termin tarihi | Fiş bazlı varsayılan + satır bazlı override (her ikisi de `ORFLINE.DUEDATE`) |
| İrsaliye ambar | Formda kaynak/hedef ambar seçici — `L_CAPIWHOUSE` lookup |
| İrsaliye sevkiyat | Taşıyıcı kodu (serbest metin alanı) eklendi |
| Sipariş `ORFICHE.STATUS` | Yeni taslak hep 1 (Öneri) — backend sabit, formda gösterilmiyor |

**Backend — yeni dosyalar:**
- `Scripts/005_OrderDrafts.sql` — `dbo.OrderDrafts` + `dbo.OrderDraftLines` (LOGOMBL DB, dbo şema, `Status` CHECK Draft/Transferred/Failed, satırlar CASCADE). Ek: fiş bazlı `DueDate`, satır bazlı `DueDate`, `LogoStatus` (default 1), `SalesmanRef`/`PayDefRef`, döviz.
- `Scripts/006_ShipmentDrafts.sql` — `dbo.ShipmentDrafts` + `dbo.ShipmentDraftLines`. Ek: `SourceIndex`/`DestIndex` (ambar), `ShipInfoCode` (taşıyıcı kodu), döviz.
- `Models/OrderDraft.cs` + `OrderDraftLine.cs`, `Models/ShipmentDraft.cs` + `ShipmentDraftLine.cs` (InvoiceDraft mirror)
- `Services/OrderDraftService.cs` — `GetAllAsync` (3-status, `Siparis` DTO döner + `IsDraft`/`DraftStatus`/`LastError`), `GetByIdAsync`, `CreateAsync`, `UpdateAsync`, `DeleteAsync`, `TransferToLogoAsync` **STUB**, `TransferBatchAsync`
- `Services/ShipmentDraftService.cs` — aynısı, `Irsaliye` DTO döner
- `Controllers/SiparisDraftController.cs` (`api/siparisdraft`), `Controllers/IrsaliyeDraftController.cs` (`api/irsaliyedraft`) — InvoiceDraftController mirror (CRUD + transfer + transfer-batch)

**Backend — güncellenen:**
- `Models/Siparis.cs` + `Models/Irsaliye.cs` — `IsDraft`/`DraftStatus`/`LastError` alanları (Fatura ile paralel, taslak listesi için)
- `Services/LookupService.cs` + `Controllers/LookupController.cs` — `GET api/lookup/warehouses` (`L_CAPIWHOUSE`, NR=ambar no)
- `Program.cs` — `OrderDraftService` + `ShipmentDraftService` DI register
- `BatchTransferResult`/`TransferOk`/`TransferFail` (InvoiceDraftService'te tanımlı) iki yeni serviste de paylaşılıyor

**Flutter — yeni dosyalar:**
- `lib/features/siparis/siparis_taslak_service.dart` — `siparisTaslakService` (`/api/SiparisDraft`)
- `lib/features/siparis/siparis_form_screen.dart` — tür seçimi (Satış/Satınalma) → cari + tarih + **fiş termini** + döviz + KDV dahil toggle + satırlar (her satırda **termin override** chip'i, boşsa fiş termini "(fiş)" etiketiyle) + ek bilgiler (satış elemanı + ödeme planı). Sipariş stok düşmediği için stok kontrolü yok.
- `lib/features/irsaliye/irsaliye_taslak_service.dart` — `irsaliyeTaslakService` (`/api/IrsaliyeDraft`)
- `lib/features/irsaliye/irsaliye_form_screen.dart` — kategorili tür seçimi → cari + tarih + döviz + KDV toggle + satırlar + **Ambar & Sevkiyat** bölümü (kaynak/hedef ambar dropdown + taşıyıcı kodu). Satış irsaliyelerinde (7/8) stok yetersizliği onay dialog'u.

**Flutter — güncellenen:**
- `lib/features/siparis/siparis_model.dart` + `lib/features/irsaliye/irsaliye_model.dart` — modele `isDraft`/`draftStatus`/`lastError` + `isTaslak`/`isAktarildi`/`isHatali` getter'ları; `SiparisTaslakModel`/`SatirModel` (fiş+satır `dueDate`) ve `IrsaliyeTaslakModel`/`SatirModel` (`sourceIndex`/`destIndex`/`shipInfoCode`) mutable form modelleri + `toJson`/`recomputeTotals`
- `lib/features/siparis/siparis_list_screen.dart` + `lib/features/irsaliye/irsaliye_list_screen.dart` — **3 sekmeli** yapıya geçirildi (Logo / Taslaklar / Hatalı), fatura listesiyle aynı kalıp: arama, sonsuz scroll, skeleton, FAB (Yeni Sipariş / Yeni İrsaliye), taslak kartında Düzenle/Aktar/Sil aksiyonları, Hatalı sekmesinde `lastError` kutusu. Eski tür/durum filtre chipleri kaldırıldı (sekmeler + arama yeterli).
- `lib/features/fatura/lookup_service.dart` — `getWarehouses()` eklendi

**Doğrulama:** `flutter analyze` → yeni dosyalarda 0 issue (kalan 9 uyarı login_screen.dart'tan, dokunulmadı). `dotnet build` → 0 warning 0 error (sandbox: `bin/Verify/`, sonra silindi).

**Test adımları:**
1. **SQL:** `005_OrderDrafts.sql` ve `006_ShipmentDrafts.sql`'i SSMS'te LOGOMBL'e karşı tek seferlik çalıştır.
2. **Backend restart:** Swagger'da `SiparisDraft`, `IrsaliyeDraft` controller'ları + `api/lookup/warehouses` görünmeli.
3. Belgeler → Siparişler → 3 sekme (Logo/Taslaklar/Hatalı). FAB "Yeni Sipariş" → tür seç → cari + satır + fiş termini + bir satıra termin override → Taslak Kaydet. Taslaklar sekmesinde görünür mü?
4. Taslakta "Aktar" → stub hata → Hatalı sekmesine düşer, `lastError` kutusu görünür. "Tekrar Dene" aynı sonucu verir (stub aktif olana dek).
5. Belgeler → İrsaliyeler → Yeni İrsaliye → Ambar & Sevkiyat bölümünde kaynak/hedef ambar (lookup dolu mu?) + taşıyıcı kodu. Satış irsaliyesi (toptan/perakende) için stok yetersizse onay dialog'u çıkar.
6. Taslak Düzenle → kayıtlı ambar/termin/taşıyıcı geri yükleniyor mu? Sil → onay → liste tazelenir.

### Düzeltmeler (cihaz testi geri bildirimi — 2026-06-01)

Faz 2 ilk testinde çıkan hatalar giderildi:

- **Sipariş Logo listesi 500** — `SiparisService` ORFICHE'de olmayan `CLOSED` kolonunu seçiyordu (`Invalid column name 'CLOSED'`). ORFICHE'de fiş bazlı CLOSED yok (kapanış satır bazlı), `0 AS Closed` yapıldı. GetAllAsync + GetByIdAsync.
- **Sipariş & İrsaliye detay 500** — `GetDetayAsync`'teki GENEXP sorgusu Dapper `ValueTuple` mapping kullanıyordu (güvenilir değil). Dynamic (DapperRow) okumaya çevrildi (her iki serviste).
- **Taslak/aktar/yeni 500** — `dbo.OrderDrafts` / `dbo.ShipmentDrafts` tabloları yoktu; `005`/`006` scriptleri LOGOMBL'de çalıştırıldı (sqlcmd ile doğrulandı: insert/line/delete OK).
- **İrsaliye formu — ambar** — Hedef ambar kaldırıldı, **sadece Kaynak Ambar** kaldı (satış irsaliyesi çıkışı; ambar transfer fişi değil). `destIndex` her zaman null gönderiliyor.
- **İrsaliye formu — taşıyıcı** — Serbest metin yerine **`L_SHPAGENT` lookup** dropdown'ı (296 kayıt). Yeni `GET api/lookup/carriers` + `lookupService.getCarriers()`. Seçilen taşıyıcının CODE'u `ShipInfoCode`'a yazılır.
- **İrsaliye listesi filtreleri** — Logo sekmesine tür (Satış Toptan/Perakende, Satınalma, iadeler) + Faturalanmış/Faturalanmamış chip filtreleri geri eklendi (taslak/hatalı sekmelerinde yok).

**Doğrulama:** `flutter analyze` (siparis/irsaliye/fatura) 0 issue, `dotnet build` 0 warning 0 error. Canlı DB'de sipariş list + draft insert + lookup sorguları test edildi.

> ⚠️ Bu düzeltmeler için backend **yeniden derlenip restart edilmeli** (CLOSED + GENEXP + carriers endpoint kod değişikliği). SQL scriptleri zaten çalıştırıldı.

### Düzeltmeler 2 + PDF çıktı (cihaz testi turu 2 — 2026-06-01)

İkinci tur cihaz testi geri bildirimi:

- **İrsaliye detay 500** — `IrsaliyeService.GetSatirlarAsync` STLINE'da olmayan `GLINENO` kolonunu seçiyordu. Bu LOGO sürümünde STLINE'da `GLINENO`/`LINENO_` yok; satır sırası `STFICHELNNO` ile alınıyor (SELECT + ORDER BY). Canlı sys.columns ile doğrulandı.
- **Sipariş & İrsaliye detay 500 (GENEXP)** — `dynamic` (DapperRow) okuma yerine concrete `GenExpRow` DTO'ya geçildi (kesin çözüm).
- **#4 Siparişe bağlı irsaliye** — `SiparisService.GetBagliIrsaliyelerAsync`: `STLINE.ORDFICHEREF = ORFICHE.LOGICALREF` üzerinden sevkiyat (irsaliye) fiş no'ları. `SiparisDetay.Irsaliyeler` (BagliBelge) eklendi; Flutter `SiparisDetayModel.irsaliyeler` + detayda "Bağlı İrsaliyeler" bölümü (dokununca irsaliye detayına gider). Canlı doğrulandı: sipariş 6700 → irsaliye 0000000000000001/0002.
- **#2 Sipariş listesi filtreleri** — Logo sekmesine Satış/Satınalma + Öneri/Sevkedilemez/Sevkedilebilir/Sevkedildi chip filtreleri (irsaliye gibi, sadece Logo sekmesinde).

**#5 PDF / görsel belge çıktısı (yeni)** — `pdf` + `printing` paketleriyle ortak, paylaşılabilir belge görseli (e-belge değil, müşteriye iletmek için):
- `lib/core/pdf/belge_pdf.dart` — `BelgePdfData`/`BelgePdfSatir` + `belgePdfOlustur()`. Türkçe karakter için `printing`'in Inter (Google Fonts) fontu. Başlık + cari + fiş bilgileri + satır tablosu + brüt/iskonto/KDV/genel toplam + açıklama + durum rozeti + ek bilgiler (termin/ambar/taşıyıcı/durum).
- `lib/core/pdf/belge_onizleme_screen.dart` — `PdfPreview` (yerleşik paylaş + yazdır).
- Bağlandığı yerler: fatura/sipariş/irsaliye **detay** ekranları AppBar'ında "Paylaş/Yazdır" (📤) — LOGO belgeleri + fatura taslağı. Sipariş/irsaliye **form** ekranlarında "Önizle/Paylaş" — taslak henüz kaydedilmemiş olsa bile mevcut form verisinden çıktı alır.

**Doğrulama:** `flutter analyze` 0 yeni issue (kalan 9 login_screen.dart, dokunulmadı), `dotnet build` 0 warning/error. Canlı DB'de detay satır sorguları + bağlı irsaliye linki test edildi.

> ⚠️ Bu turun backend değişiklikleri (STFICHELNNO, GENEXP DTO, bağlı irsaliye) için backend **yeniden derlenip restart edilmeli**. SQL/tablo tarafı değişmedi.

### Düzeltmeler 3 (cihaz testi turu 3 — 2026-06-01)

- **`LineNo` rezerve kelime hatası** — Bu SQL Server'da `LineNo` rezerve; `SELECT ... AS LineNo` (parantezsiz) syntax hatası → fatura/sipariş/irsaliye **detay satır** sorguları hep 500. Üç serviste de `AS [LineNo]` yapıldı. (Önceki turda "sqlcmd artefaktı" sanılıp atlanmıştı — gerçekmiş.)
- **FaturaService `GLINENO`** — STLINE'da yok → `INVOICELNNO`.
- **İrsaliye satırları boş** — `STLINE.INVOICEREF IS NULL` filtresi tüm satırları eliyordu; bu LOGO'da faturalanmamış satırda INVOICEREF = **0** (NULL değil). Filtre kaldırıldı → irsaliye kendi satırlarını gösteriyor.
- **Fatura listesi (Aktarılan) boş** — En kritik bulgu: `LG_126_01_INVOICE.TRCODE` bu kurulumda **1-13** (STFICHE ile aynı) kodlama kullanıyor, FaturaService'in beklediği **31-56** değil. `TRCODE IN (31..56)` → 0 eşleşme. Düzeltme: filtre `IN (1,2,3,4,6,7,8,9)`, ad `StokTrCodeMapper.GetName(code, isInvoice:true)`. Bağlı belge adları da düzeltildi (irsaliye→StokTrCodeMapper false, sipariş→OrderCodeMapper). Canlı: 669 fatura geliyor.
- **Flutter fatura kartı/detay** — `FaturaTuru` enum'u 31-56 olduğu için LOGO faturalarında (1-9) null dönüyordu. `FaturaModel`'e `displayAd`/`displayRenk`/`displayIkon` (trCodeName + 1-9 kategori tabanlı) eklendi; liste kartı ve detay header bunları kullanıyor.

> ⚠️ **Bilinen tutarsızlık (Faz 3 için):** Taslak faturalar `FaturaTuru` 31-56 ile kaydediliyor; LOGO INVOICE ise 1-10 kullanıyor. Gerçek aktarım (`TransferToLogoAsync`) yazılırken taslak TRCODE'u 31-56 → 1-10 map'lenmeli (ör. 37→7, 38→8, 31→1). Sipariş/irsaliye zaten doğru LOGO kodlarını kullanıyor.

> Backend bu turda da **yeniden derlenip restart edilmeli**. SQL/tablo değişmedi.

### Belge zinciri navigasyonu + dashboard hızlı işlemler (tur 4 — 2026-06-01, sadece Flutter)

- **Belge zinciri gezinme** — Sipariş → bağlı irsaliye → bağlı fatura → bağlı irsaliye/sipariş zinciri artık tıklanabilir:
  - Fatura detayındaki "Bağlı Belgeler" (irsaliyeler/siparişler) satırları tıklanabilir oldu (`_belgeGrubu` InkWell + chevron) → ilgili irsaliye/sipariş detayına gider.
  - İrsaliye detayına "Bağlı Fatura" bölümü eklendi (faturalandıysa, `STFICHE.INVOICEREF`/`INVNO`) → fatura detayına gider (`_BagliFaturaKart`, minimal `FaturaModel` ile push; detay id'den yüklenir).
  - Sipariş detayındaki bağlı irsaliyeler zaten tıklanabilirdi (önceki tur).
- **Dashboard hızlı işlemler** — Ana sayfadaki kartlar artık çalışıyor: Cari ara → `CariListScreen`, Faturalar → `FaturaListScreen`, Tahsilat → `BugunTahsilatlarScreen`, Stok → `MalzemeListScreen` (`_buildAction` artık `onTap` alıyor).

**Doğrulama:** `flutter analyze` 0 issue. **Backend değişmedi → restart gerekmez**, sadece uygulamayı yeniden çalıştır (hot restart).

**Sıradaki (Faz 3):** LOGO'ya gerçek aktarım (`TransferToLogoAsync` — REST API / SP / manuel INSERT kararı; taslak 31-56 → LOGO 1-10 TRCODE map'i) ve zincir akışlar: "Siparişten irsaliye kes" / "İrsaliyeden fatura kes".

### PDF offline font düzeltmesi (cihaz testi geri bildirimi — 2026-06-01, sadece Flutter)

**Sorun:** Cari ekstresi ve stok (malzeme) ekstresinde "belge önizleme" açılıyor ama sürekli dönüyor, hiç PDF gelmiyordu. (Aynı koşulda irsaliye/sipariş PDF'i de donardı.)

**Kök neden:** PDF üreticileri Türkçe karakter (ş/ğ/ı) için Inter fontunu `PdfGoogleFonts.inter*()` ile **çalışma anında Google CDN'den (fonts.gstatic.com) indiriyordu**. Cihaz internete ulaşamadığında (offline ya da sadece backend'in olduğu LAN'da) indirme askıda kalıyor, `PdfPreview` sonsuza dek spinner gösteriyordu. "Önceden alabiliyordum" çünkü font ya cache'liydi ya da o an internet vardı.

**Çözüm — Inter fontları artık gömülü asset:**
- `assets/fonts/Inter-Regular.ttf` + `Inter-SemiBold.ttf` + `Inter-Bold.ttf` eklendi (rsms/inter v4.1 statik TTF'ler), `pubspec.yaml` `flutter: assets:` altına kaydedildi.
- `lib/core/pdf/pdf_fonts.dart` — YENİ. `PdfFonts.regular()/semiBold()/bold()` asset'ten `pw.Font.ttf(rootBundle.load(...))` ile yükler + ilk yüklemeden sonra cache'ler. İnternet gerekmez.
- `lib/core/pdf/belge_pdf.dart` — `PdfGoogleFonts.interRegular/interSemiBold` → `PdfFonts.regular/semiBold`. `printing` importu kaldırıldı (artık gerekmiyor).
- `lib/core/utils/pdf_exporter.dart` — `_PdfTheme.load()` içinde `PdfGoogleFonts.interRegular/interBold` → `PdfFonts.regular/bold`. (`printing` importu `Printing.sharePdf` için kaldı.)

**Not:** Fatura detayındaki PDF butonu hâlâ kasıtlı stub (`_pdfStub` → "backend şablon modülü gelince"); bu turda dokunulmadı (kullanıcı kapsam dışı bıraktı).

**Doğrulama:** `flutter analyze` (değişen 3 dosya) → 0 issue.

> ⚠️ Asset eklendiği için **hot reload yetmez** — uygulamayı tam kapatıp yeniden çalıştırın (`flutter run`, gerekirse `flutter clean`). Backend değişmedi, restart gerekmez.

---

## Önceki

## En son ne yapıldı (2026-06-01 — dördüncü tur)

### A. Sipariş & İrsaliye okuma katmanı (Faz 1 — paralel)

Yeni iki feature: mobil kullanıcı LOGO'daki sipariş ve irsaliyeleri listeleyip detayını inceleyebilir. Yazma ve zincir akışları (sipariş→irsaliye→fatura) sonraki fazlarda.

**Karar matrisi** (kullanıcı ile, 2026-06-01):

| Soru | Karar |
|---|---|
| Sıra | Paralel — sipariş + irsaliye birlikte |
| Kapsam (bu faz) | Sadece okuma: liste + detay + filtre. Taslak yazma Faz 2'de, zincir akışlar Faz 3'te. |
| LOGO akış zincirleri | "İrsaliyeden fatura kes" / "Siparişten irsaliye kes" — Faz 3'te tam akarım |
| Sipariş TRCODE | 1 (Satış / alınan) + 2 (Satınalma / verilen) |
| İrsaliye TRCODE | 1, 2, 3, 6, 7, 8 — satış/satınalma + iadeler. Sarf/üretim/transfer/sayım fişleri (11,12,13,14,25,26,50,51) hariç. |

**Backend — yeni dosyalar:**
- `Models/Siparis.cs`, `Models/SiparisSatir.cs` (+`SiparisDetay`) — ORFICHE/ORFLINE projection
- `Models/Irsaliye.cs`, `Models/IrsaliyeSatir.cs` (+`IrsaliyeDetay`) — STFICHE/STLINE projection (STLINE'da `INVOICEREF IS NULL` → saf irsaliye satırı)
- `Services/SiparisService.cs` — `GetAllAsync` (TRCODE 1/2 filter, status, cari, tarih, arama, sayfalı) + `GetByIdAsync` + `GetSatirlarAsync` + `GetDetayAsync`
- `Services/IrsaliyeService.cs` — `GetAllAsync` (TRCODE 1,2,3,6,7,8 + faturalandi filtresi + arama) + detay
- `Services/OrderCodeMapper.cs` — ORFICHE.STATUS (1=Öneri, 2=Sevkedilemez, 3=Sevkedilebilir, 4=Sevkedildi — canlı doğrulanmış) ve TRCODE (1=Satış, 2=Satınalma)
- `Controllers/SiparisController.cs`, `Controllers/IrsaliyeController.cs` — list / id / satırlar / detay endpoint'leri
- `Program.cs` — `SiparisService` + `IrsaliyeService` DI register

**Flutter — yeni dosyalar:**
- `lib/features/siparis/siparis_model.dart` — `SiparisModel` + `SiparisSatirModel` + `SiparisDetayModel` + `SiparisTuru` enum + `SiparisDurumu` enum (renk + ikon)
- `lib/features/siparis/siparis_service.dart` — `siparisService` singleton (Dio)
- `lib/features/siparis/siparis_list_screen.dart` — arama + tür filtresi (Satış/Satınalma) + durum chipleri, sayfalı sonsuz scroll
- `lib/features/siparis/siparis_detay_screen.dart` — header + özet (sipariş/sevkedildi/bekleyen + sevk oranı progressbar) + satırlar (her satırın bekleyen miktarı + termin + sevk progressbar)
- `lib/features/irsaliye/irsaliye_model.dart` — `IrsaliyeTuru` enum (Satış/Satınalma/İade kategorileri)
- `lib/features/irsaliye/irsaliye_service.dart`
- `lib/features/irsaliye/irsaliye_list_screen.dart` — kategori filtresi (Satış Toptan/Perakende/Satınalma/Satış İade/Satınalma İade) + faturalandı/faturalanmamış chip
- `lib/features/irsaliye/irsaliye_detay_screen.dart` — header + brüt/iskonto/KDV özeti + satırlar + faturalandı rozeti

**Flutter — güncellenen:**
- `lib/features/belgeler/belgeler_screen.dart` — İrsaliyeler ve Siparişler kartları "Yakında" rozetinden aktife alındı

**Doğrulama:** `flutter analyze` 0 issue, `dotnet build` 0 warning 0 error.

**Test adımları:**
1. Belgeler sekmesinden Siparişler'e gir → liste yüklenir mi? Satış/Satınalma chiplerine tıkla, filtrelenir.
2. Sipariş kartına tıkla → detay açılır. Sevk oranı progressbar, satırlardaki bekleyen miktar doğru mu?
3. Belgeler → İrsaliyeler → kategori chipleri → faturalandı filtresi → detay → brüt/iskonto/KDV özeti.
4. Backend restart: yeni `/api/Siparis` ve `/api/Irsaliye` endpoint'leri Swagger'da görünmeli.

### B. Fatura formu: KDV dahil/hariç toggle

`fatura_form_screen.dart`'a fatura genelinde tek bir switch eklendi. Açıkken birim fiyatlar KDV dahil olarak yorumlanır. Toggle değiştirildiğinde her satırın `priceC.text` otomatik dönüştürülür (× veya ÷ `(1 + KDV/100)`), satır toplamı aynı kalır. Backend'e her durumda KDV hariç fiyat gider (`InvoiceDrafts.PRICE` LOGO standardıyla uyumlu).

- `_LineDraft` getter'ları artık `bool kdvDahil` parametresi alıyor: `priceNet`, `total`, `vatAmount`, `lineNet`. `toModel(kdvDahil)` her zaman KDV hariç değerleri persistler.
- `_LineCard` `kdvDahil` parametresi alıyor; birim fiyat label'ı "Birim fiyat (KDV dahil)" olarak değişir.
- Yeni `_KdvDahilToggle` widget'ı — Switch + alt açıklama satırı (durum metni).
- Toggle taslak yüklenince varsayılan `false` (backend hep KDV hariç saklar).

### C. Lookup endpoint temizliği

Faturanın "Ek Bilgiler" bloğundan 5 dropdown kaldırıldı (kullanılmayan/karışıklık yaratan): Sevkiyat Adresi, Taşıyıcı, Sevkiyat Türü, Taşıma Tipi, Ticari İşlem Grubu. Sadece Satış Elemanı + Ödeme Planı kaldı.

- Backend: `LookupController.cs`'ten 5 endpoint, `LookupService.cs`'ten 5 metod, `InvoiceDraft.cs`'ten 5 field, `InvoiceDraftService.cs` SELECT/INSERT/UPDATE SQL'lerinden 5 alan silindi. DB kolonları (nullable) dokunulmadı.
- Flutter: `lookup_service.dart`'tan 5 metod, `fatura_model.dart`'taki 5 ref alanı, `fatura_form_screen.dart`'taki state + `_ExtraFieldsTile` props sadeleştirildi.
- `_loadLookups()` artık hatayı yutmuyor — `loading` + `error` state'iyle UI'a yansıyor, "Tekrar dene" butonu var, boş listede dropdown disable + "LOGO'da tanımlı satış elemanı bulunamadı" uyarısı.

---

## Önceki

## En son ne yapıldı (2026-05-25 — üçüncü tur: Fatura feature)

### Karar matrisi (kullanıcı ile)
| Soru | Karar |
|---|---|
| Aktarım modeli | **Taslak + Aktar** — mobilden taslak oluşturulur, "LOGO'ya Aktar" butonuyla aktarılır. Offline-tolerant. |
| Taslak deposu | Backend'in kendi DB'sinde (LOGOMBL `dbo.InvoiceDrafts`) — LOGO INVOICE'a dokunulmaz |
| Fatura türü kapsamı | TRCODE 31..56 — tüm türler (satış, satınalma, iade, hizmet, vade farkı, müstahsil) |
| e-Fatura/e-Arşiv | Yok — LOGO'ya aktarım yeterli; e-Fatura'yı kullanıcı LOGO'dan keser |
| PDF | Bu turda placeholder (snackbar) — backend şablon modülü sonraki epic |
| Nav stratejisi | "Raporlar" tab'ı **"Belgeler"** şemsiyesine dönüştü → Fatura/İrsaliye/Sipariş kartları |
| Cari/Malzeme seçimi | Tam ekran arama (mevcut listelerin **`selectionMode` parametresi**) + cari detayında **"Fatura Kes" kısayolu** |
| State management | StatefulWidget + setState + Form key (CLAUDE.md kuralı — Riverpod yok henüz) |

### 1. Backend: yeni `InvoiceDrafts` + `InvoiceDraftLines` tabloları
- **DDL** (`Scripts/001_InvoiceDrafts.sql`): LOGOMBL DB'sinde `dbo` schema. `Status NVARCHAR(20) CHECK ('Draft'|'Transferred'|'Failed')`, `TransferredInvoiceId` (LOGO'ya aktarılınca dolar), `LastError` (Failed durumunda), `CreatedBy` (JWT claim'den). Satırlar `ON DELETE CASCADE`. Index: Status+CreatedAt, ClientRef, CreatedBy.
- Çalıştırma: SSMS'te tek seferlik `USE LOGOMBL; ...` çalıştır.

### 2. Backend: 5 yeni model + 2 yeni service + 2 yeni controller
- **Modeller** (`Models/`): `Fatura`, `FaturaSatir`, `FaturaDetay` (+`BagliBelge`), `InvoiceDraft`, `InvoiceDraftLine`.
- **`Services/FaturaService.cs`** — LOGO okuma:
  - `GetAllAsync(offset,limit,search?,baslangic?,bitis?,trCode?,cariId?)` — `LG_xxx_yy_INVOICE` JOIN `CLCARD`, sadece `CANCELLED=0` + `TRCODE IN (31..56)`. Multi-filter, sayfalı.
  - `GetByIdAsync(id)`, `GetSatirlarAsync(invoiceId)` — `STLINE` JOIN `ITEMS`+`UNITSETL`, LINETYPE→ad mapping.
  - `GetDetayAsync(id)` — header + satırlar + bağlı belgeler + GENEXP1..4 bundle.
  - `GetBaglantiliIrsaliyelerAsync(invoiceId)` — `STFICHE.INVOICEREF`.
  - `GetBaglantiliSiparislerAsync(invoiceId)` — `STLINE.ORDFICHEREF` DISTINCT JOIN `ORFICHE`.
- **`Services/InvoiceDraftService.cs`** — Taslak CRUD (Dapper):
  - Create/Update/Delete/GetAll/GetById (transaction; lines delete-and-insert pattern update için).
  - **`TransferToLogoAsync(draftId)` — ŞU AN STUB**: status'u `Failed`, `LastError`'a "LOGO aktarım modülü henüz aktif değil" yazıyor. Gerçek implementation için LOGO entegrasyon stratejisi (REST API / SP / manuel INSERT) netleşmesi gerekiyor. Bu sayede UI/akış tamamen test edilebilir, kullanıcı stratejiyi belirleyince transfer kısmı doldurulur.
  - `TransferBatchAsync(ids)` — toplu aktarım sonucu (`BatchTransferResult`).
- **Controllers** (`FaturaController`, `InvoiceDraftController`): REST endpoint'leri. `CreatedAtAction`, `NoContent`, `409 Conflict` (stub transfer).
- **`Services/TrCodeMapper.cs`** — fatura yardımcıları eklendi: `IsInvoice/IsSatisFaturasi/IsSatinalmaFaturasi/IsIade/GetKategori`.
- **`Program.cs`** — DI kaydı: `FaturaService`, `InvoiceDraftService`.

### 3. Mobil: `app_spacing.dart` + "Belgeler" şemsiye sekmesi
- **`lib/core/theme/app_spacing.dart`** — YENİ (CLAUDE.md'de geçiyordu ama dosya yoktu). `xs=4, sm=8, md=16, lg=24, xl=32`. Yeni fatura ekranları bunu kullanır.
- **`lib/features/shell/main_shell.dart`** — 4. tab "Raporlar" placeholder'ı kaldırıldı → `BelgelerScreen`. İkon `folder_rounded`. `_PlaceholderScreen` da silindi.
- **`lib/features/belgeler/belgeler_screen.dart`** — YENİ: 3 büyük kart (Faturalar aktif, İrsaliyeler ve Siparişler "Yakında" rozetiyle disabled).

### 4. Mobil: Fatura feature klasörü (`lib/features/fatura/`)
- **`fatura_model.dart`** — `FaturaTuru` enum (13 değer, her birinin TRCODE/ad/kategori/ikon/renk getter'ları), `FaturaModel` (liste için), `FaturaSatirModel` (LINETYPE→renk), `FaturaDetayModel` + `BagliBelgeModel`, `FaturaTaslakModel` + `FaturaTaslakSatirModel` (form için mutable, `recomputeTotals()` ile canlı hesap).
- **`fatura_service.dart`** — Okuma: `getFaturalar/getFaturaById/getFaturaDetay/getFaturaPdf`. Singleton `faturaService`. `_handleError` Türkçe.
- **`fatura_taslak_service.dart`** — CRUD + transfer: `getTaslaklar(status)/getTaslakById/createTaslak/updateTaslak/deleteTaslak/transferTaslak/transferBatch`.
- **`fatura_list_screen.dart`** — 3 sekmeli (`TabBar`): **Aktarılan / Taslaklar / Hatalı**. Her sekme bağımsız state (`AutomaticKeepAliveClientMixin`), debounced search (300ms), infinite scroll (300px threshold), pull-to-refresh, skeleton loading, empty/error state. Taslak/Hatalı sekmelerinde kartta inline action'lar: [Düzenle] [Aktar/Tekrar Dene] [Sil]. Hatalı'da kırmızı `LastError` şeridi. FAB: "+ Yeni Fatura".
- **`fatura_detay_screen.dart`** — Hero kart (tür rengi gradient, NET TOTAL büyük, draft/failed rozet), aksiyon barı (PDF/Paylaş/Düzenle/Aktar), satırlar tablosu (her satırda lineType rengi şerit), toplamlar kartı, bağlı belgeler bölümü (irsaliye + sipariş), açıklamalar (GENEXP1..4). Hem LOGO hem taslak için tek ekran.
- **`fatura_form_screen.dart`** — YENİ pattern (proje ilk form'u):
  - **Adım 1**: Tür seçimi (gruplu liste — Satış / Satınalma / İade), `taslakId != null` ise atlanır.
  - **Form**: Tür rozeti + cari seçici (tam ekran `CariListScreen(selectionMode:true)` push, geri pop ile dönüş) + tarih picker + fiş no + belge no + satır listesi.
  - **Satır**: Malzeme seçici (`MalzemeListScreen(selectionMode:true)`), miktar/birim fiyat/KDV%/iskonto numeric field'leri, canlı satır toplamı.
  - **Sticky bottom**: 4 toplam mini (Brüt/İskonto/KDV/Net) + iki buton **[Taslak Kaydet]** ve **[Kaydet ve Aktar]**.
  - Validation: cari zorunlu, en az 1 satır, satırlarda miktar > 0 ve malzeme/açıklama dolu.
  - Async gap guard'ları (`mounted` kontrolü her await sonrası).
  - "Kaydet ve Aktar" → önce create/update, sonra transfer çağrısı. Transfer başarısız olsa bile taslak kaydedilir → kullanıcı kaybetmez.

### 5. Mobil: Cari/Malzeme listelerine `selectionMode` parametresi
- **`cari_list_screen.dart`** — `final bool selectionMode` constructor parametresi. `selectionMode=true` → AppBar başlık "Cari Seç", tap → `Navigator.pop(context, cari)` (detay push yerine).
- **`malzeme_list_screen.dart`** — Aynı pattern. AppBar başlık "Malzeme Seç".
- Default `false` olduğu için mevcut shell/navigation çağrıları etkilenmiyor.

### 6. Mobil: Cari detay'da "Fatura Kes" kısayolu
- **`cari_detay_screen.dart`** — Hero kart aksiyon satırına 4. buton eklendi (`Icons.receipt_long_rounded`, "Fatura"). Tıklayınca `FaturaFormScreen(onceSecilenCari: _cari)` push. Form'da cari önceden dolu + kilit ikonu gösterir.

### Doğrulama
- **Backend**: `dotnet build` → 0 hata. Swagger UI'da `/api/Fatura/*` ve `/api/InvoiceDraft/*` görünmeli. SQL DDL'i bir kez çalıştır.
- **Mobil**: `flutter analyze` → **0 issue**. Belgeler tab → Faturalar → 3 sekme. "+ Yeni Fatura" → tür seç → form → cari seç (tam ekran) → satır ekle → malzeme seç → miktar/fiyat → canlı toplam → Taslak Kaydet veya Kaydet ve Aktar. Cari detayda "Fatura" butonu → form'da cari kilitli.
- Aktarım şu an stub döndüreceği için Aktar denenince Hatalı sekmesinde görünecek + LastError'da net açıklama olacak. Bu beklenen.

### Henüz YOK / sonraki turlar
- **Gerçek LOGO transfer mantığı** — InvoiceDraftService.TransferToLogoAsync'in stub kısmı. Kullanıcı LOGO entegrasyon stratejisini (REST/SP/INSERT) belirleyince yazılacak.
- **PDF üretimi** — şu an snackbar uyarısı; backend şablon modülü ve özelleştirme sonraki epic.
- **Liste filter butonu** (tarih aralığı + fatura türü chip'leri) — backend filtreleri hazır, mobilde sadece UI eksik.
- **İrsaliye / Sipariş feature'ları** — Belgeler şemsiyesinde "Yakında" görünüyor; aynı taslak+aktar pattern'i ile gelecek.

### Dokunulan dosyalar (bu tur)
**Backend (`C:\Users\SULO\source\repos\LogoMobileApi`):**
- `Scripts/001_InvoiceDrafts.sql` — YENİ
- `Models/Fatura.cs`, `FaturaSatir.cs`, `FaturaDetay.cs`, `InvoiceDraft.cs`, `InvoiceDraftLine.cs` — YENİ
- `Services/FaturaService.cs`, `InvoiceDraftService.cs` — YENİ
- `Services/TrCodeMapper.cs` — fatura yardımcıları (IsInvoice, IsSatis, IsIade, GetKategori)
- `Controllers/FaturaController.cs`, `InvoiceDraftController.cs` — YENİ
- `Program.cs` — DI kaydı

**Mobil (`C:\dev\logo_mobil`):**
- `lib/core/theme/app_spacing.dart` — YENİ
- `lib/features/shell/main_shell.dart` — "Belgeler" tab + placeholder silindi
- `lib/features/belgeler/belgeler_screen.dart` — YENİ
- `lib/features/fatura/fatura_model.dart`, `fatura_service.dart`, `fatura_taslak_service.dart`, `fatura_list_screen.dart`, `fatura_detay_screen.dart`, `fatura_form_screen.dart` — YENİ (6 dosya)
- `lib/features/cari/cari_list_screen.dart` — `selectionMode` parametresi
- `lib/features/malzeme/malzeme_list_screen.dart` — `selectionMode` parametresi
- `lib/features/cari/cari_detay_screen.dart` — "Fatura" aksiyon butonu + `_newFatura`

---

# Önceki

Son güncelleme: 2026-05-25 (malzeme ekstresi iyileştirme + malzeme resmi + cari e-fatura/e-arşiv rozeti + PDF paylaşım)

## En son ne yapıldı (2026-05-25 — ikinci tur)

### 1. Malzeme hareket ekranı — giriş/çıkış filtresi, ambar, planlanan hariç

**İstek:** Stok ekstresinde Giriş/Çıkış chip filtresi, planlanan üretim fişlerini gizleme, her satırda ilgili ambar.

**Çözüm:**
- **Backend** (`MalzemeService.GetHareketlerAsync`):
  - Yeni `bool? giris` parametresi: `IOCODE IN (1,2)` giriş / `IOCODE IN (3,4)` çıkış.
  - `L_CAPIWHOUSE` JOIN: `IOCODE IN (1,2) → DESTINDEX`, aksi → `SOURCEINDEX`. Sonuca `Ambar` kolonu eklendi.
  - Planlanan fiş filtresi: `ISNULL(sf.PRODSTAT,0)=0 AND ISNULL(sl.LPRODSTAT,0)=0` — 0 = güncel, 1 = planlanan; tüm fiş türlerine uygulanır.
  - `Controller`: `?giris=true/false/null` query param eklendi.
- **Mobil** (`malzeme_hareket_screen.dart`):
  - 3'lü segment buton: Tümü / Giriş / Çıkış (server-side filter).
  - Hareket kartına ambar satırı (`Icons.warehouse_outlined`).
  - `MalzemeHareket.ambar` modeli ve `getHareketler(giris:)` parametresi eklendi.

### 2. Malzeme detay overflow + alanların kopyalanabilirliği

**Sorun:** "Açıklama 2" uzun olunca `RIGHT OVERFLOWED BY 48 PIXELS`. Cari ve malzeme detayında alanlar kopyalanamıyordu.

**Çözüm:** `_InfoSatir` ve cari detay `_infoRow` widget'larında `Spacer + Text` yapısı `Expanded(child: SelectableText(...))`'e dönüştürüldü. Hem overflow gitti hem uzun bas → kopyala menüsü.

### 3. Cari kartında e-Fatura / e-Arşiv rozeti

**Eşleme:** `CLCARD.ISPERSCOMP` — 0 → e-Fatura mükellefi (EF), 1 → e-Arşiv mükellefi (EA, şahıs şirketi).
- **Backend** (`CariService.GetAllAsync` + `GetByIdAsync`): `CASE WHEN ISNULL(clc.ISPERSCOMP,0)=1 THEN 2 ELSE 1 END AS EInvoiceType`.
- **Mobil** (`cari_model.dart`): `eInvoiceType` (int) + `eFatura`/`eArsiv` getter'ları.
- **UI** (`cari_card.dart`): Avatar `Stack`'e sarıldı; sağ üst köşeye renkli **EF/EA** rozeti (Positioned, white border).
- **Detay** (`cari_detay_screen.dart`): Hero kartının altına "e-Fatura/e-Arşiv Mükellefi" bilgi şeridi.

### 4. Malzeme resmi (LG_XXX_FIRMDOC.LDATA)

**Doğrulanmış şema:** `INFOTYP=20`, `DOCTYP=0`, `DOCNR=11`, `INFOREF = ITEMS.LOGICALREF`. (Logo kolon adları **INFOTYP/DOCTYP** — sondaki E yok.)

**Çözüm:**
- **Backend:**
  - `MalzemeService.GetResimAsync(int id)` — `ExecuteScalarAsync` ile `byte[]` döner; hata olursa `null` → controller 404 verir (UI ikon fallback gösterir).
  - `MalzemeController` yeni endpoint: `GET /api/Malzeme/{id}/resim` → `image/png` + `Cache-Control: public, max-age=86400`.
  - Teşhis endpoint'i: `GET /api/Malzeme/{id}/resim-debug` → FIRMDOC'taki tüm satırlar (INFOTYP/DOCTYP/DOCNR/LDataBoyut) — yeni kayıt türünde sabit doğrulamak için.
  - `GetFirmDocRowsAsync` helper.
- **Mobil:**
  - Paket: `cached_network_image: ^3.4.1`.
  - `lib/core/api/api_client.dart`: `cachedTokenSync` + `getToken()` cache mekanizması. `main.dart`'ta app başında ön yükleme. `auth_service` login/logout cache'i temizler/yeniler. (Aksi takdirde her resim için secure storage'a gidip uygulamayı yavaşlatıyordu.)
  - Yeni widget `lib/features/malzeme/malzeme_image.dart`:
    - `CachedNetworkImage` + `Authorization: Bearer` header.
    - Yüklenirken/hata olunca configurable ikon fallback (`Icons.inventory_2_rounded`).
    - **Tıklayınca tam ekran zoom önizleme**: `Hero` animasyonu + `InteractiveViewer` (0.8x–5x), siyah barrier + X kapama butonu.
  - Liste ve detay hero kartında `Icon` → `MalzemeImage` ile değiştirildi.

### 5. PDF olarak paylaşma (Cari Ekstre + Malzeme Ekstre)

**İstek:** Müşterilere WhatsApp/Mail ile ekstre PDF göndermek.

**Çözüm:**
- Paketler: `pdf: ^3.11.0`, `printing: ^5.13.0`.
- `lib/core/utils/pdf_exporter.dart` — Türkçe karakter destekli (Inter Google Font), A4 multi-page:
  - `buildCariEkstrePdf(cari, ekstre)` → Cari bilgi kartı + Devir/Borç/Alacak/Kapanış özet kartları + tablolu hareketler + toplam satırı.
  - `buildMalzemeEkstrePdf(malzemeId, malzemeAdi, birim, hareketler, baslangic, bitis)` → Toplam Giriş/Çıkış/Net/Tutar kartları + hareket tablosu (Tarih, İşlem/Fiş, Ambar, Cari/Açıklama, Miktar, Tutar).
  - Header'da başlık + müşteri/malzeme + dönem + oluşturma tarihi; footer'da sayfa numarası.
  - `sharePdf(bytes, filename)` → `Printing.sharePdf` ile sistem paylaş sheet'i.
- **Butonlar:** Her iki ekranın AppBar'ına 🟥 `Icons.picture_as_pdf_rounded`. Dosya adı: `Ekstre_<CariAdi>_<bas>-<bit>.pdf` / `MalzemeEkstre_<MalzemeAdi>_<bas>-<bit>.pdf`.

### Dokunulan dosyalar (bu tur)
**Backend:**
- `Services/MalzemeService.cs` — `GetHareketlerAsync` (giris param, ambar, planlanan filter), `GetResimAsync` (yeni), `GetFirmDocRowsAsync` (yeni).
- `Controllers/MalzemeController.cs` — `?giris=` + `/{id}/resim` + `/{id}/resim-debug`.
- `Services/CariService.cs` — `GetAllAsync` + `GetByIdAsync` (EInvoiceType).
- `Models/MalzemeHareket.cs` — `Ambar`.
- `Models/Cari.cs` — `EInvoiceType`.

**Mobil:**
- `lib/features/malzeme/malzeme_model.dart` — `MalzemeHareket.ambar`.
- `lib/features/malzeme/malzeme_service.dart` — `giris` param + `resimUrl`.
- `lib/features/malzeme/malzeme_hareket_screen.dart` — yön chip'leri, ambar satırı, PDF butonu.
- `lib/features/malzeme/malzeme_detay_screen.dart` — `MalzemeImage`, `_InfoSatir` overflow fix.
- `lib/features/malzeme/malzeme_list_screen.dart` — `MalzemeImage` ile thumbnail.
- `lib/features/malzeme/malzeme_image.dart` — YENİ (thumbnail + Hero tam ekran preview).
- `lib/features/cari/cari_model.dart` — `eInvoiceType`/`eFatura`/`eArsiv`.
- `lib/features/cari/cari_card.dart` — Stack avatar + EF/EA rozet.
- `lib/features/cari/cari_detay_screen.dart` — bilgi şeridi + `SelectableText`.
- `lib/features/cari/cari_ekstre_screen.dart` — PDF paylaş butonu.
- `lib/core/api/api_client.dart` — token cache.
- `lib/core/utils/pdf_exporter.dart` — YENİ.
- `lib/main.dart` — token preload.
- `lib/features/auth/auth_service.dart` — cache invalidation.
- `pubspec.yaml` — `cached_network_image`, `pdf`, `printing`.

### Test
1. **Backend restart** (process'i kapatıp `dotnet run`).
2. **Flutter hot restart** (R), gerekirse uninstall+install (yeni native paketler için).
3. Cariler → EF/EA rozetleri.
4. Malzeme listesi → resimler görünmeli (yoksa fallback ikon).
5. Resme tıkla → tam ekran zoom.
6. Malzeme detay → Açıklama 2 taşmıyor, uzun bas → kopyala.
7. Malzeme ekstresi → Giriş/Çıkış/Tümü, ambar satırı, planlanan fişler yok.
8. AppBar 🟥 PDF butonu → paylaş sheet → WhatsApp/Mail.
9. Cari ekstresi → AppBar 🟥 PDF butonu.

---

# Önceki

Son güncelleme: 2026-05-25 (cari sayfalama + cari ekstresi)

## En son ne yapıldı (2026-05-25)

### 1. Cari listesi: sayfalama (offset/limit/search)

**Sorun:** `/api/Cari` `TOP 50` ile hard-coded'du, hep ilk 50 cari gelirdi. Arama da sadece gelen 50 üzerinde client-side filtreydi.

**Çözüm:**
- **Backend** (`CariService.GetAllAsync` + `CariController.GetAll`): `TOP 50` kaldırıldı → `OFFSET ... FETCH NEXT @Limit ROWS ONLY`. Query parametreleri `offset` (def 0), `limit` (def 50), `search` (CODE/DEFINITION_/CITY üzerinde `LIKE`). `try/catch` ile sarmalama eklendi.
- **Mobil** (`cari_service.dart` + `cari_list_screen.dart`): `getCariler` artık `offset/limit/search` alıyor. Ekran malzeme paternine çevrildi — `ScrollController` ile sona 300px yaklaşınca otomatik sonraki sayfa, 300ms debounce ile server-side arama.

**Test:**
1. Backend restart: `cd C:\Users\SULO\source\repos\LogoMobileApi\LogoMobileApi && dotnet run`.
2. Mobilde Cariler sekmesine gir → ilk 50 yüklenmeli.
3. Aşağı kaydır → loading spinner + sonraki 50 otomatik gelmeli.
4. Tümü bitince loading durmalı.
5. Arama kutusuna yaz → 300ms sonra server'dan eşleşenler 50'şer gelmeli, sayfalama arama içinde de çalışmalı.
6. Pull-to-refresh çalışmalı.

---

### 2. Cari hesap ekstresi

**İstek:** Tarih aralığına göre devir bakiyesi + hareketler (yürüyen bakiye ile) + dönem toplam borç/alacak + kapanış bakiyesi.

**Bonus — irsaliye davranışı:** Faturalanmamış sevk irsaliyeleri cari hareketlerinde görünmüyor. Bu **Logo standardı** — STFICHE sadece stok hareketi yazar, faturalanana kadar `CLFLINE`'a düşmez. **Kod değişikliği yapılmadı**, davranış doğru.

**Çözüm:**
- **Backend** (`LogoMobileApi`):
  - Yeni model `Models/CariEkstre.cs` (`CariEkstre` + `CariEkstreSatir`, satırlarda `YurutulenBakiye`).
  - `CariService.GetEkstreAsync(cariId, baslangic?, bitis?)` — tek bağlantıda iki sorgu (devir = `DATE_ < @Baslangic`, hareketler = aralık içi `CLFLINE`, `CANCELLED=0`). Running balance + toplamlar C# tarafında, `TrCodeMapper` ile işlem adı doluyor. Default: yıl başı → bugün.
  - Yeni endpoint: `GET /api/cari/{id}/ekstre?baslangic=&bitis=`.
- **Mobil** (`logo_mobil`):
  - `cari_ekstre_model.dart`, `cari_service.dart::getEkstre`.
  - `cari_ekstre_screen.dart` — AppBar'da takvim ikonu (`showDateRangePicker`), header'da Devir & Kapanış kutuları, liste satırlarında tarih · işlem adı · belge no/açıklama · tutar + yürüyen bakiye, footer'da Toplam Borç | Alacak | Net. Pull-to-refresh + shimmer + boş/hata durumları.
  - `cari_detay_screen.dart` — "Son hareketler" başlığının sağına **Ekstre** linki (ikon + yazı) eklendi; tıklayınca yeni ekrana push.

**Test:**

**Backend:**
1. `dotnet run` restart.
2. JWT ile: `GET /api/cari/{id}/ekstre?baslangic=2026-01-01&bitis=2026-05-25`.
3. `DevirBakiyesi + (ToplamBorc - ToplamAlacak) == KapanisBakiyesi` doğrulanmalı.
4. Hareketler'in son satırının `YurutulenBakiye`'si `KapanisBakiyesi`'ne eşit olmalı.
5. Parametresiz çağrı → yıl başı–bugün dönmeli.

**Mobil:**
1. `flutter run` → Cariler → bir cariye gir.
2. "Son hareketler" başlığının sağında **Ekstre** linki görünmeli.
3. Tıkla → Ekstre ekranı, yıl başı–bugün ile yüklenmeli.
4. Header'da Devir + Kapanış görünmeli; her satırın altında yürüyen bakiye; ilk satır = Devir ± satır tutarı.
5. AppBar takvim ikonu → date range picker (Türkçe).
6. Tarih değiştir → liste + devir/kapanış güncellenmeli.
7. Pull-to-refresh, boş durum ("Bu aralıkta hareket yok" + buton), hata ekranı.
8. Renk doğruluğu: Müşteri borçlu (pozitif) = **kırmızı**, Biz borçluyuz (negatif) = **yeşil**.

**SQL sanity (opsiyonel):** Logo Tiger'da aynı cari + aynı tarih aralığı ekstresi ile devir/kapanış değerlerini karşılaştır.

**Dosyalar:**
- Backend: `Models/CariEkstre.cs` (yeni), `Services/CariService.cs::GetEkstreAsync` (yeni), `Controllers/CariController.cs::GetEkstre` (yeni), `Services/CariService.cs::GetAllAsync` + `Controllers/CariController.cs::GetAll` (sayfalama).
- Mobil: `lib/features/cari/cari_ekstre_model.dart` (yeni), `cari_ekstre_screen.dart` (yeni), `cari_service.dart` (+getEkstre, +offset/limit/search), `cari_list_screen.dart` (sayfalama paterni), `cari_detay_screen.dart` (Ekstre linki).

---

## Önceki: Malzeme detayı (Faz 1 + Faz 2)

**Malzeme detayı — Faz 1 + Faz 2 tamamlandı.** Backend + Flutter eşli değişiklikler, `flutter analyze` temiz, backend yeniden başlatıldı (port 5249).

### Faz 1 (detay zenginleştirme)
1. **Özel Kod 1–4** — `ITEMS.SPECODE`, `SPECODE2-4`
2. **Tanımlı satınalma & satış fiyatı** — `LG_{firma}_PRCLIST` OUTER APPLY (PTYPE=1/2), `L_CURRENCYLIST` ile döviz kodu (TL/USD/EUR)
3a. **Açıklama 2** — `ITEMS.NAME2`
4. **Malzeme türü** — `ITEMS.CARDTYPE` (10→Hammadde, 11→Yarı Mamul). Hem detayda hem liste rozetinde (HM/YM).

### Faz 2 (gerçek hareketler + ekstre)
3b. **Son satınalma/satış fiyatı (gerçekleşen)** — `STLINE`'dan TRCODE=1 (satınalma) ve TRCODE IN (7,8) (satış) için en güncel `PRICE`.
5. **Malzeme ekstresi** — `GET /api/Malzeme/{id}/hareketler?baslangic=&bitis=`
   - `STLINE` düz kronolojik liste (LINETYPE=0), iptal edilenler hariç (COALESCE üzerinden parent CANCELLED kontrolü)
   - `STFICHE`/`INVOICE`/`CLCARD` JOIN'leri ile fiş no + cari adı
   - `IOCODE` ile giriş/çıkış yönü
   - Yeni `StokTrCodeMapper` — bağlam bilen (fatura mı irsaliye mi) TRCODE→ad çevirisi (STLINE.TRCODE 1 = irsaliye bağlamında "Satınalma İrsaliyesi", fatura bağlamında "Satınalma Faturası")
   - Flutter: yeni `MalzemeHareketScreen` — Türkçe tarih aralığı seçici + tür chip'leri (Tümü/Faturalar/İrsaliyeler/Üretim&Sarf) + giriş/çıkış renkli kart liste

### Altyapı
- `flutter_localizations` paketi eklendi — Türkçe tarih seçici için `GlobalMaterialLocalizations` delegate'leri + `locale: Locale('tr','TR')` (main.dart)

## Dokunulan dosyalar

**Backend (`C:\Users\SULO\source\repos\LogoMobileApi`):**
- `Services/MalzemeService.cs` — GetAllAsync, GetByIdAsync, GetHareketlerAsync (yeni)
- `Services/StokTrCodeMapper.cs` — YENİ
- `Models/Malzeme.cs` — `Tur` eklendi
- `Models/MalzemeDetay.cs` — yeni alanlar (özel kodlar, fiyatlar, açıklama 2, vb.)
- `Models/MalzemeHareket.cs` — YENİ
- `Controllers/MalzemeController.cs` — `/{id}/hareketler` ucu

**Flutter (`C:\dev\logo_mobil`):**
- `lib/features/malzeme/malzeme_model.dart` — komple yenilendi (Malzeme + MalzemeDetay + MalzemeHareket)
- `lib/features/malzeme/malzeme_service.dart` — `getHareketler` eklendi
- `lib/features/malzeme/malzeme_list_screen.dart` — Türü rozeti (`_TurChip`)
- `lib/features/malzeme/malzeme_detay_screen.dart` — Ekstre butonu + `_FiyatSection` + genişletilmiş `_BilgiSection`
- `lib/features/malzeme/malzeme_hareket_screen.dart` — YENİ
- `lib/main.dart` — localization delegate'leri
- `pubspec.yaml` — `flutter_localizations`

## Nerede kaldık

Tamamlandı. Kullanıcı testi bekliyor.

## Opsiyonel sonraki adımlar (kullanıcı isterse)
- **Siparişler (`ORFLINE`)** — alınan/verilen siparişleri ekstreye veya ayrı sekme olarak ekle
- **Cari hareketlerine tarih filtresi** — aynı kalıp `CariService.GetHareketlerAsync`'e uygulanır
- **Gerçek ambar adları** — şu an `MalzemeService.GetByIdAsync` ikinci sorgusunda hardcoded CASE var; `L_CAPIWHOUSE` JOIN ile dinamik yapılabilir
- **CARDTYPE eşlemesini genişlet** — şu an sadece 10/11 var; doc'ta 12=Ambalaj, 13=Ticari Kaygı vb.
- **PRCLIST fiyatlarına geçerlilik tarihi** — şu an son fiyat geliyor ama `BEGDATE`/`ENDDATE` ile aktif olup olmadığı kontrol edilmiyor

## Kullanıcı talimatları (hatırlatma)

- "LOGO ile yaparken sadece attığım LOGO dökümanlarını izle datayı öğren öyle yap ya da bana sor öyle yap." → Şema bilinmiyorsa `LOGO_ERP_DATABASE_REFERENCE.md`'ye bak, yine yoksa sor — tahmin etme.
- Backend + Flutter iki ayrı repo; her endpoint değişikliği iki tarafta da güncellenir.
- "Sen bir flutter expert'sin skills klasörlerini unutma.".
