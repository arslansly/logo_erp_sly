# LOGO ERP VERİTABANI REFERANS DÖKÜMANI
## Claude Code için Kapsamlı SQL Rehberi — MSSQL Server / TIGER

> **Hazırlayan:** SLY  
> **Tarih:** 2026-05-22  
> **Platform:** MSSQL Server — Logo Tiger 3 Enterprise  
> **Firma numarası örneği:** 126 (sorularda `XXX` yerine gerçek firma no yazılır)  
> **Dönem örneği:** 01 (sorularda `YY` yerine gerçek dönem no yazılır)

---

## İÇİNDEKİLER

1. Tablo İsimlendirme Kuralı
2. Temel Kavramlar ve Genel Kurallar
3. Tarih Formatı — KRİTİK
4. Süre Formatı — KRİTİK
5. Tablo Kataloğu (Kısa Referans)
6. Sistem Tabloları (L_)
7. Malzeme Kartları — LG_XXX_ITEMS
8. Cari Hesap Kartları — LG_XXX_CLCARD
9. Ambarlar — L_CAPIWHOUSE
10. Stok Miktarları — LV_XXX_YY_GNTOTST
11. Malzeme Ambar Bilgileri — LG_XXX_INVDEF
12. Faturalar — LG_XXX_YY_INVOICE
13. Malzeme Fişleri / İrsaliyeler — LG_XXX_YY_STFICHE & STLINE
14. Siparişler — LG_XXX_YY_ORFICHE & ORFLINE
15. Üretim Emirleri — LG_XXX_PRODORD
16. Operasyonlar — LG_XXX_OPERTION & OPRTREQ
17. İş Emirleri — LG_XXX_DISPLINE
18. Level=0 Tablolar (Firma Bağımsız)
19. İlişki Haritası
20. Standart Sorgu Şablonları
21. Performans Kuralları
22. Sık Yapılan Hatalar

---

## 1. TABLO İSİMLENDİRME KURALI

Logo ERP veritabanında her tablo adı, tablonun kapsamını doğrudan yansıtır. Bu yapıyı anlamak her sorgunun temelini oluşturur.

### Level 0 — Firma Bağımsız Tablolar

Bu tablolar `L_` ile başlar ya da `LG_` ile başlayıp herhangi bir firma/dönem numarası almaz. Firma bilgisi tablo adında değil, tablo içindeki `FIRMNR` alanında tutulur. Bu yüzden bu tablolara JOIN yaparken `FIRMNR` filtresi eklemeyi **unutmayın**.

```sql
-- DOĞRU:
FROM LG_SLSMAN SLS WITH (NOLOCK)
WHERE SLS.FIRMNR = 126

-- YANLIŞ (tüm firmaların verisini getirir):
FROM LG_SLSMAN SLS WITH (NOLOCK)
```

Örnekler: `L_CURRENCYLIST`, `L_CAPIUSER`, `L_CAPIWHOUSE`, `LG_SLSMAN`, `LG_CONTACTS`, `LG_WHLIST`

### Level 1 — Firma Bağımlı Kartlar (Dönem Bağımsız)

Format: `LG_{FIRMNR}_TABLO`

Bu tablolar tanım ve kart tablolarıdır. Malzeme kartları, cari kartlar, üretim emirleri gibi. Dönem numarası **almaz**.

```
LG_126_ITEMS       → Malzeme kartları
LG_126_CLCARD      → Cari hesap kartları
LG_126_PRODORD     → Üretim emirleri
LG_126_OPERTION    → Operasyon kartları
LG_126_WORKSTAT    → İş istasyonu kartları
LG_126_DISPLINE    → İş emirleri
```

### Level 2 — Firma + Dönem Bağımlı Hareketler

Format: `LG_{FIRMNR}_{DONEM}_TABLO`

Hareketler hem firmaya hem döneme bağlıdır.

```
LG_126_01_INVOICE  → Faturalar
LG_126_01_STFICHE  → Malzeme fişleri (irsaliye, sarf, üretimden giriş…)
LG_126_01_STLINE   → Malzeme fiş satırları (hem irsaliye hem fatura satırları)
LG_126_01_ORFICHE  → Sipariş fişleri
LG_126_01_ORFLINE  → Sipariş satırları
```

---

## 2. TEMEL KAVRAMLAR VE GENEL KURALLAR

**LOGICALREF:** Her tablonun birincil anahtarıdır. `Longint (int)` tipindedir ve otomatik artar. Tüm JOIN ilişkileri bu alan üzerinden kurulur.

**ACTIVE:** Kayıt durumunu gösterir. `0 = Aktif`, `1 = Pasif`. Pasif kayıtlar raporlara dahil edilmemelidir. Neredeyse tüm sorgularda `WHERE ACTIVE = 0` filtresi gerekir.

**REF ile biten alanlar:** Başka bir tabloya yabancı anahtar (FK) taşır. Örneğin `CLIENTREF → LG_XXX_CLCARD.LOGICALREF`, `STOCKREF → LG_XXX_ITEMS.LOGICALREF`.

**TRCODE:** Aynı tabloda birden fazla işlem türü bulunur. Bu alan işlem türünü belirler ve raporlarda filtre olarak **mutlaka** kullanılır (alış/satış, irsaliye/fatura vb.).

**LINETYPE:** STLINE ve ORFLINE tablolarında satır türünü belirtir. `0 = Malzeme satırı`. Raporlarda genellikle sadece malzeme satırları (`LINETYPE = 0`) istenir, aksi belirtilmedikçe bu filtre eklenir.

**WITH (NOLOCK):** Canlı sistemde rapor alırken lock oluşturmamak için tüm tablolarda kullanılır.

---

## 3. TARİH FORMATI — KRİTİK

Logo Tiger veritabanında tarihler **iki farklı formatta** saklanır ve bunları karıştırmak hatalı sonuç verir.

### Longint (Pascal) Formatı
Bazı tablolarda tarih alanları `DATEADD(day, ALAN_ADI, '1899-12-30')` ile `DATE`'e çevrilir.

```sql
-- PRODORD.DATE_ için:
DATEADD(day, PRODORD.DATE_, '1899-12-30') AS UretimEmriTarihi

-- DISPLINE.OPBEGDATE için:
DATEADD(day, DISP.OPBEGDATE, '1899-12-30') AS BaslangicTarihi
```

### DateTime Formatı
INVOICE, STFICHE, ORFICHE gibi hareket tablolarında `DATE_` alanı doğrudan `DATETIME` / `INT` olarak saklanır ve doğrudan kullanılabilir:

```sql
-- INVOICE, STFICHE, ORFICHE için:
WHERE I.DATE_ >= '2024-01-01' AND I.DATE_ <= '2024-12-31'
```

**Kural:** Sorgu yazmadan önce ilgili tablonun `DATE_` tipini kontrol edin. Uzun sayısal değer görüyorsanız `DATEADD` dönüşümü gerekir.

---

## 4. SÜRE FORMATI — KRİTİK

Operasyon, iş emri ve üretim tablolarındaki süre alanları (`RUNTIME`, `SETUPTIME`, `FIXEDSETUPTIME`, `TRANSBATCHTIME`, `WAITBATCHTIME`, `INSPTIME`, `QUETIME`, `HEADTIME`, `TAILTIME`) **saniye veya dakika değildir**. Logo'nun kendi iç `int` formatıyla encode edilmiştir.

Bu alanlar üzerinde `RUNTIME / 60` gibi aritmetik işlem **yanlış sonuç verir**.

Görsel gösterim için Logo'nun UDF'si kullanılır:

```sql
-- DOĞRU:
SELECT dbo.LG_INTTOTIME(DISP.RUNTIME) AS IslemSuresi
-- Çıktı örneği: '108:40:38' (SS:DD:DD:SS formatı)

-- YANLIŞ:
SELECT DISP.RUNTIME / 3600 AS SaatSayisi  -- HATA ÜRETIR
```

Sıfır kontrolü için ham değer kullanılabilir: `WHERE DISP.RUNTIME > 0`

---

## 5. TABLO KATALOĞU — KISA REFERANS

| Tablo | Level | Açıklama |
|-------|-------|----------|
| `L_CURRENCYLIST` | 0 | Döviz türleri |
| `L_CAPIUSER` | 0 | Kullanıcılar |
| `L_CAPIWHOUSE` | 0 | Ambar listesi |
| `LG_SLSMAN` | 0 | Satış elemanları |
| `LG_CONTACTS` | 0 | İlgili kişiler |
| `LG_XXX_ITEMS` | 1 | Malzeme kartları |
| `LG_XXX_CLCARD` | 1 | Cari hesap kartları |
| `LG_XXX_INVDEF` | 1 | Malzeme ambar bilgileri (min/max stok) |
| `LG_XXX_UNITSETF` | 1 | Birim set başlıkları |
| `LG_XXX_UNITSETL` | 1 | Birim set satırları |
| `LG_XXX_PAYPLANS` | 1 | Ödeme planları |
| `LG_XXX_BOMASTER` | 1 | Ürün reçetesi başlıkları (BOM) |
| `LG_XXX_BOMLINE` | 1 | Ürün reçetesi satırları |
| `LG_XXX_PRODORD` | 1 | Üretim emirleri |
| `LG_XXX_OPERTION` | 1 | Operasyon kartları |
| `LG_XXX_OPRTREQ` | 1 | Operasyon ihtiyaçları (iş ist. + süreler) |
| `LG_XXX_WORKSTAT` | 1 | İş istasyonu kartları |
| `LG_XXX_WSGRPF` | 1 | İş istasyonu grupları |
| `LG_XXX_DISPLINE` | 1 | İş emirleri (üretim emri operasyon bazlı) |
| `LG_XXX_SPECODES` | 1 | Özel kodlar tanım tablosu |
| `LG_XXX_YY_INVOICE` | 2 | Fatura başlıkları |
| `LG_XXX_YY_STFICHE` | 2 | Malzeme fiş başlıkları |
| `LG_XXX_YY_STLINE` | 2 | Malzeme fiş satırları (fatura + irsaliye) |
| `LG_XXX_YY_ORFICHE` | 2 | Sipariş fiş başlıkları |
| `LG_XXX_YY_ORFLINE` | 2 | Sipariş satırları |
| `LG_XXX_YY_PAYTRANS` | 2 | Ödeme / tahsilat fişleri |
| `LG_XXX_YY_CLFLINE` | 2 | Cari hesap fiş satırları |
| `LV_XXX_YY_GNTOTST` | View | Anlık stok miktarları |

---

## 6. SİSTEM TABLOLARI (L_)

### L_CURRENCYLIST — Döviz Türleri

```sql
-- Temel alanlar:
CURTYPE   (int)        -- Döviz kodu (1=USD, 2=EUR vs.)
CURCODE   (varchar)    -- ISO kodu ('USD', 'EUR', 'TRY'...)
CURNAME   (varchar)    -- Döviz adı
FIRMNR    (int)        -- Firma numarası

-- Kullanım:
FROM L_CURRENCYLIST C WITH (NOLOCK)
WHERE C.FIRMNR = 126 AND C.CURTYPE = 1  -- USD
```

### L_CAPIUSER — Kullanıcılar

```sql
NR           (int)       -- Kullanıcı numarası (FK olarak kullanılır)
NAME         (varchar)   -- Kullanıcı adı
DEFINITION_  (varchar)   -- Tam adı
```

### L_CAPIWHOUSE — Ambar Listesi

```sql
NR       (int)      -- Ambar numarası (SOURCEINDEX/DESTINDEX ile eşleşir)
FIRMNR   (int)      -- Firma numarası
NAME     (varchar)  -- Ambar adı

-- Kullanım:
FROM L_CAPIWHOUSE WH WITH (NOLOCK)
WHERE WH.FIRMNR = 126
```

---

## 7. MALZEME KARTLARI — LG_XXX_ITEMS

Firma bağımlı (Level=1). Tüm malzeme/ürün tanımları bu tablodadır.

```sql
LOGICALREF   (int)       -- Birincil anahtar
CODE         (varchar)   -- Malzeme kodu
NAME         (varchar)   -- Malzeme adı
DEFINITION_  (varchar)   -- Uzun açıklama
ACTIVE       (int)       -- 0=Aktif, 1=Pasif

CARDTYPE     (int)       -- Malzeme türü:
                         --   1  = Ticari Mal (TM)
                         --   2  = Kaba Ürün (KK)
                         --   3  = Mamul (DM)
                         --   4  = Sabit Kıymet — genelde raporlara dahil edilmez
                         --   10 = Hammadde (HM)
                         --   11 = Yarı Mamul (YM)
                         --   12 = Ambalaj (MM)
                         --   13 = Ticari Kaygı (TK)
                         --   20 = Malzeme Sınıfı Genel — raporlara dahil edilmez
                         --   21 = Malzeme Sınıfı Tablolu — raporlara dahil edilmez

SPECODE      (varchar)   -- Özel kod
STGRPCODE    (varchar)   -- Stok grup kodu
UNITSETREF   (int)       -- Birim set referansı → LG_XXX_UNITSETF.LOGICALREF
CLASSTYPE    (int)       -- Sınıf tipi

-- Standart filtre (aktif, sınıf dışı malzemeler):
WHERE ITEMS.ACTIVE = 0
  AND ITEMS.CARDTYPE NOT IN (4, 20, 21)
```

---

## 8. CARİ HESAP KARTLARI — LG_XXX_CLCARD

Firma bağımlı (Level=1). Müşteri, tedarikçi ve diğer cari hesaplar bu tablodadır.

```sql
LOGICALREF   (int)       -- Birincil anahtar
CODE         (varchar)   -- Cari kodu
DEFINITION_  (varchar)   -- Cari adı (JOIN'de ad için bu alan kullanılır)
ACTIVE       (int)       -- 0=Aktif, 1=Pasif

CARDTYPE     (int)       -- Cari türü:
                         --   1 = Alıcı (Müşteri)
                         --   2 = Satıcı (Tedarikçi)
                         --   3 = Alıcı/Satıcı
                         --   4 = Personel
                         --   5 = Diğer

SPECODE      (varchar)   -- Özel kod
CYPHCODE     (varchar)   -- Yetki kodu
ADDR1        (varchar)   -- Adres
CITYCODE     (varchar)   -- Şehir kodu (bazen plaka numarası)
COUNTRY      (varchar)   -- Ülke
TAXNR        (varchar)   -- Vergi numarası
TELNRS1      (varchar)   -- Telefon
EMAILADDR    (varchar)   -- E-posta
PAYDEFREF    (int)       -- Ödeme planı ref. → LG_XXX_PAYPLANS.LOGICALREF

-- Standart filtre:
WHERE CLCARD.ACTIVE = 0
```

---

## 9. AMBARLAR — L_CAPIWHOUSE

Firma bazında ambar listesi. `SOURCEINDEX` ve `DESTINDEX` alanlarıyla eşleşir.

```sql
SELECT WH.NR, WH.NAME
FROM L_CAPIWHOUSE WH WITH (NOLOCK)
WHERE WH.FIRMNR = 126
ORDER BY WH.NR
```

---

## 10. STOK MİKTARLARI — LV_XXX_YY_GNTOTST

Bu bir **view**'dır, tablo değildir. Anlık stok miktarlarını hızlı almak için kullanılır.

```sql
STOCKREF   (int)     -- Malzeme referansı → LG_XXX_ITEMS.LOGICALREF
INVENNO    (int)     -- Ambar numarası. -1 verilirse TÜM ambarlardaki toplam gelir.
ONHAND     (float)   -- Fiili stok: eldeki fiziki miktar (satış rezerveleri hariç)
RESERVED   (float)   -- Satış siparişleri için rezerve edilen miktar

-- Tüm ambarlar toplamı:
SELECT ST.STOCKREF, SUM(ST.ONHAND) AS ToplamStok
FROM LV_126_01_GNTOTST ST WITH (NOLOCK)
WHERE ST.INVENNO = -1
GROUP BY ST.STOCKREF

-- Belirli ambar:
WHERE ST.INVENNO = 1
```

**ÖNEMLİ — Terminoloji:**
`ONHAND` = Fiili Stok (rezerveler düşülmez)
`ONHAND - RESERVED` = Kullanılabilir Stok

---

## 11. MALZEME AMBAR BİLGİLERİ — LG_XXX_INVDEF

Firma bağımlı (Level=1). Malzemelerin ambar bazlı minimum/maksimum stok seviyelerini tutar.

```sql
LOGICALREF    (int)     -- Birincil anahtar
ITEMREF       (int)     -- Malzeme ref. → LG_XXX_ITEMS.LOGICALREF
INVENNO       (int)     -- Ambar numarası
MINLEVEL      (float)   -- Asgari stok seviyesi
MAXLEVEL      (float)   -- Azami stok seviyesi
MINLEVELCTRL  (int)     -- Minimum stok kontrolü (0=Pasif, 1=Aktif) — RAPORLARDA DİKKAT ALINMAZ

-- Not: Bir malzeme için birden fazla ambarda tanım olabilir.
-- Asgari stok = Bloke olmayan ambarların MINLEVEL toplamı
```

---

## 12. FATURALAR — LG_XXX_YY_INVOICE

Firma + dönem bağımlı (Level=2). Fatura başlıklarını tutar. **Fatura satırları STLINE tablosundadır.**

### Temel Alanlar

```sql
LOGICALREF          (int)       -- Birincil anahtar
FICHENO             (varchar)   -- Fatura numarası
DATE_               (datetime)  -- Fatura tarihi
FTIME               (int)       -- Fatura saati (HHMMSS)
DOCODE              (varchar)   -- Belge/fiş numarası
CLIENTREF           (int)       -- Cari hesap ref. → LG_XXX_CLCARD.LOGICALREF

TRCODE              (int)       -- İşlem türü (aşağıya bakın)
ACTIVE              (int)       -- 0=Aktif, 1=Pasif
CANCELLED           (int)       -- 0=İptal değil, 1=İptal

SOURCEINDEX         (int)       -- Kaynak ambar numarası
DESTINDEX           (int)       -- Hedef ambar numarası

NETTOTAL            (float)     -- Net toplam
GROSSTOTAL          (float)     -- Brüt toplam
TOTALDISCOUNTS      (float)     -- Toplam iskonto
TOTALEXPENSES       (float)     -- Toplam masraf
REPORTRATE          (float)     -- Raporlama döviz kuru

GENEXP1, GENEXP2, GENEXP3, GENEXP4  (varchar)  -- Genel açıklama satırları
CAPIBLOCK_CREADEDDATE   (datetime)  -- Oluşturulma tarihi
CAPIBLOCK_MODIFIEDDATE  (datetime)  -- Değiştirilme tarihi
```

### TRCODE Değerleri — INVOICE

```
1  = Satınalma Faturası
2  = Perakende Satış İade Faturası
3  = Toptan Satış İade Faturası
4  = Alınan Hizmet Faturası
5  = Alınan Proforma Fatura
6  = Satınalma İade Faturası
7  = Perakende Satış Faturası
8  = Toptan Satış Faturası
9  = Verilen Hizmet Faturası
10 = Verilen Proforma Fatura
11 = Verilen Vade Farkı Faturası
12 = Alınan Vade Farkı Faturası
13 = Satınalma Fiyat Farkı Faturası
14 = Satış Fiyat Farkı Faturası
```

---

## 13. MALZEME FİŞLERİ / İRSALİYELER — LG_XXX_YY_STFICHE & STLINE

### 13.1 Fiş Başlıkları — LG_XXX_YY_STFICHE

Firma + dönem bağımlı (Level=2). İrsaliye, sarf, üretimden giriş, ambar transferi gibi tüm malzeme fişi başlıkları bu tablodadır.

```sql
LOGICALREF       (int)       -- Birincil anahtar
FICHENO          (varchar)   -- Fiş numarası
DATE_            (datetime)  -- Fiş tarihi
FTIME            (int)       -- Fiş saati
DOCODE           (varchar)   -- Belge numarası
INVNO            (varchar)   -- Fatura numarası (faturalanmış ise)
CLIENTREF        (int)       -- Cari hesap ref. → LG_XXX_CLCARD.LOGICALREF
INVOICEREF       (int)       -- Fatura ref. → LG_XXX_YY_INVOICE.LOGICALREF
PRODORDERREF     (int)       -- Üretim emri ref. → LG_XXX_PRODORD.LOGICALREF (0 ise bağımsız)
PRODSTAT         (int)       -- 0=Güncel/Gerçekleşen, 1=Planlanan
SOURCEINDEX      (int)       -- Kaynak ambar
DESTINDEX        (int)       -- Hedef ambar
TRCODE           (int)       -- İşlem türü (aşağıya bakın)
CANCELLED        (int)       -- 0=Aktif, 1=İptal
BILLED           (int)       -- 1=Faturalanmış
GENEXP1, GENEXP2, GENEXP3  (varchar)  -- Genel açıklama
```

### TRCODE Değerleri — STFICHE

```
1  = Satınalma İrsaliyesi
2  = Perakende Satış İade İrsaliyesi   ← CANLI DOĞRULANMIŞ (Logo dokümanlarında "Perakende Satış İrsaliyesi" yazar, yanlış)
3  = Toptan Satış İade İrsaliyesi
4  = Konsinye Çıkış İrsaliyesi
5  = Konsinye Giriş İrsaliyesi
6  = Satınalma İade İrsaliyesi
7  = Perakende Satış İrsaliyesi
8  = Toptan Satış İrsaliyesi
9  = Konsinye Çıkış İrsaliyesi
10 = Konsinye Giriş İade İrsaliyesi
11 = Fire Fişi
12 = SARF FİŞİ              ← Üretim hammadde sarfı
13 = ÜRETİMDEN GİRİŞ FİŞİ  ← Üretilen mamulün ambara girişi
14 = Devir Fişi (açılış)
25 = Ambar Transferi Fişi
26 = Mühtasil İrsaliyesi
50 = Sayım Fazlası Fişi
51 = Sayım Eksiği Fişi
```

### PRODSTAT Değerleri (Üretim Fişleri)

```
PRODSTAT = 1  →  PLANLANAN fiş (reçete x miktar)
PRODSTAT = 0  →  GÜNCEL / Gerçekleşen fiş
```

### 13.2 Fiş Satırları — LG_XXX_YY_STLINE

**Hem irsaliye hem fatura satırları bu tablodadır!** `INVOICEREF` veya `STFICHEREF` alanı dolu olmasına göre hangi fişe ait olduğu anlaşılır.

```sql
LOGICALREF    (int)     -- Birincil anahtar
STOCKREF      (int)     -- Malzeme ref. → LG_XXX_ITEMS.LOGICALREF
CLIENTREF     (int)     -- Cari hesap ref. → LG_XXX_CLCARD.LOGICALREF
INVOICEREF    (int)     -- Fatura ref. → LG_XXX_YY_INVOICE.LOGICALREF
STFICHEREF    (int)     -- İrsaliye ref. → LG_XXX_YY_STFICHE.LOGICALREF

LINETYPE      (int)     -- Satır türü:
                        --   0 = Malzeme (ITEMS) ← en çok kullanılan
                        --   1 = Hizmet
                        --   2 = Masraf
                        --   3 = Promosyon
                        --   4 = İskonto/Artırım
                        --   5 = Alt Malzeme
                        --   8 = Sabit Kıymet

TRCODE        (int)     -- İşlem türü (STFICHE veya INVOICE ile aynı)
DATE_         (datetime)-- Hareket tarihi

AMOUNT        (float)   -- Miktar (fişteki birimde)
PRICE         (float)   -- Birim fiyat
TOTAL         (float)   -- Satır toplam
VAT           (float)   -- KDV oranı
VATAMNT       (float)   -- KDV tutarı
DISTDISC      (float)   -- Dağıtılan iskonto
LINENET       (float)   -- Net tutar

UOMREF        (int)     -- Birim ref. → LG_XXX_UNITSETL.LOGICALREF
UINFO1        (float)   -- Birim çevrimi 1
UINFO2        (float)   -- Birim çevrimi 2
LINEEXP       (varchar) -- Satır açıklaması
SALESMANREF   (int)     -- Satış elemanı ref. → LG_SLSMAN.LOGICALREF
VARIANTREF    (int)     -- Varyant ref.
```

---

## 14. SİPARİŞLER — LG_XXX_YY_ORFICHE & ORFLINE

### 14.1 Sipariş Başlıkları — LG_XXX_YY_ORFICHE

```sql
LOGICALREF    (int)     -- Birincil anahtar
FICHENO       (varchar) -- Fiş numarası
DATE_         (int)     -- Sipariş tarihi (Long int → DATEADD dönüşümü gerekebilir)
DOCODE        (varchar) -- Sipariş/belge numarası
CLIENTREF     (int)     -- Cari hesap ref. → LG_XXX_CLCARD.LOGICALREF

TRCODE        (int)     -- İşlem türü:
                        --   1 = Satış Siparişi (Alınan Sipariş)
                        --   2 = Satınalma Siparişi (Verilen Sipariş)

STATUS        (int)     -- Sipariş durumu (aşağıya bakın — ÇOK KRİTİK!)
CANCELLED     (int)     -- 0=Aktif, 1=İptal
CLOSED        (int)     -- 0=Açık, 1=Kapalı
SOURCEINDEX   (int)     -- Kaynak ambar
NETTOTAL      (float)   -- Net toplam
GENEXP1, GENEXP2  (varchar)  -- Genel açıklama
```

### ⚠️ STATUS Değerleri — ORFICHE (CANLI DOĞRULANMIŞTIR)

Bu değerler Logo dokümantasyonunda muğlak yazılmıştır; aşağıdaki gerçek değerleri kullanın:

```
STATUS = 1  →  Öneri (Proposal) — kaydedildi, işleme açılmadı
STATUS = 2  →  SEVKEDİLEMEZ — blokeli/askıda! ("Sevkedilebilir" SANILMASIN)
STATUS = 3  →  Sevkedilebilir / Onaylı — aktif bekleyen sipariş
STATUS = 4  →  Sevkedildi / Tamamlandı
```

**Bekleyen siparişler için daima `STATUS = 3` kullanın.**

### 14.2 Sipariş Satırları — LG_XXX_YY_ORFLINE

```sql
LOGICALREF    (int)     -- Birincil anahtar
STOCKREF      (int)     -- Malzeme ref. → LG_XXX_ITEMS.LOGICALREF
CLIENTREF     (int)     -- Cari hesap ref.
ORDFICHEREF   (int)     -- Sipariş başlık ref. → LG_XXX_YY_ORFICHE.LOGICALREF
LINETYPE      (int)     -- Satır türü (0=Malzeme, 1=Hizmet, 2=Masraf, 4=İskonto)
TRCODE        (int)     -- İşlem türü
DATE_         (int)     -- Satır tarihi

AMOUNT        (float)   -- Sipariş miktarı
SHIPPEDAMOUNT (float)   -- Sevk edilen miktar
PRICE         (float)   -- Birim fiyat
TOTAL         (float)   -- Satır toplam
VAT           (float)   -- KDV oranı
LINENET       (float)   -- Net tutar
DUEDATE       (int)     -- Termin tarihi (Long format)
CLOSED        (int)     -- 0=Açık, 1=Kapalı
STATUS        (int)     -- Satır bazlı onay (ORFICHE.STATUS ile aynı kod tablosu)
LINEEXP       (varchar) -- Satır açıklaması
SALESMANREF   (int)     -- Satış elemanı ref.
```

### Bekleyen Sipariş Filtresi

```sql
-- Bekleyen satınalma siparişleri:
WHERE ORF.TRCODE = 2
  AND ORF.STATUS = 3      -- Sevkedilebilir/Onaylı
  AND ORF.CANCELLED = 0
  AND ORL.LINETYPE = 0
  AND ORL.CLOSED = 0
  AND (ORL.AMOUNT - ORL.SHIPPEDAMOUNT) > 0

-- Bekleyen satış siparişleri:
-- Aynı filtre, sadece ORF.TRCODE = 1
```

---

## 15. ÜRETİM EMİRLERİ — LG_XXX_PRODORD

Firma bağımlı, **dönem bağımsız** (Level=1). Her üretim emri için tek satır.

```sql
LOGICALREF    (int)      -- Birincil anahtar
FICHENO       (varchar)  -- Üretim emri numarası (örn: ÜR2026002543)
DATE_         (int)      -- Tarih (Long format → DATEADD(day, DATE_, '1899-12-30'))

ITEMREF       (int)      -- Üretilecek ürün ref. → LG_XXX_ITEMS.LOGICALREF
UOMREF        (int)      -- Birim ref. → LG_XXX_UNITSETL.LOGICALREF
PLNAMOUNT     (float)    -- Planlanan üretim miktarı
ACTAMOUNT     (float)    -- Gerçekleşen üretim miktarı

MASTERREF     (int)      -- Ürün reçetesi ref. → LG_XXX_BOMASTER.LOGICALREF
ROUTINGREF    (int)      -- Üretim rotası ref.

CANCELLED     (int)      -- 0=Aktif, 1=İptal
RELEASED      (int)      -- 0=Serbest bırakılmamış, 1=Serbest bırakılmış
SCHEDULED     (int)      -- 0=Çizelgelenmemiş, 1=Çizelgelenmiş

STATUS        (int)      -- Üretim emri durumu (aşağıya bakın)
FACTORYNR     (int)      -- Fabrika numarası
GENEXP1       (varchar)  -- Açıklama 1
```

### ⚠️ STATUS Değerleri — PRODORD (ORFICHE.STATUS ile KARIŞTIRMAYIN)

```
STATUS = 0  →  Başlamadı
STATUS = 1  →  Devam Ediyor
STATUS = 2  →  DURDURULDU (ORFICHE'de STATUS=2 "Sevkedilemez" demekti, burada farklı!)
STATUS = 3  →  Tamamlandı
STATUS = 4  →  Kapandı
```

### Tarih Dönüşümü

```sql
-- PRODORD.DATE_ için:
DATEADD(day, PROD.DATE_, '1899-12-30') AS UretimEmriTarihi
```

### Sarf Fişleriyle Join

```sql
-- Üretim emri → Sarf fişleri → Sarf satırları
FROM LG_126_PRODORD PROD WITH (NOLOCK)
LEFT JOIN LG_126_01_STFICHE SF WITH (NOLOCK)
    ON SF.PRODORDERREF = PROD.LOGICALREF
    AND SF.TRCODE = 12      -- Sarf fişi
    AND SF.CANCELLED = 0
    AND SF.PRODORDERREF > 0 -- Üretim emrine bağlı olduğunu teyit et
LEFT JOIN LG_126_01_STLINE SL WITH (NOLOCK)
    ON SL.STFICHEREF = SF.LOGICALREF
    AND SL.LINETYPE = 0
WHERE PROD.CANCELLED = 0
```

---

## 16. OPERASYONLAR — LG_XXX_OPERTION & OPRTREQ

### 16.1 Operasyon Kartları — LG_XXX_OPERTION

Firma bağımlı (Level=1). Operasyon tanım kartları.

```sql
LOGICALREF    (int)      -- Birincil anahtar
CODE          (varchar)  -- Operasyon kodu
NAME          (varchar)  -- Operasyon adı
SPECODE       (varchar)  -- Özel kod
CYPHCODE      (varchar)  -- Yetki kodu
ACTIVE        (int)      -- 0=Kullanımda (aktif)
DISTTYPE      (int)      -- 0=Dağıtılacak, 1=Dağıtılmayacak
DOCOUNTING    (int)      -- Sayım merkezi (0=Hayır, 1=Evet)
CARDTYPE      (int)      -- 0=Genel, 1=Üretim, 2=Kalite Kontrol
```

### 16.2 Operasyon İhtiyaçları — LG_XXX_OPRTREQ

Bir operasyonun hangi iş istasyonunda yapılabileceği ve süre bilgileri.

```sql
LOGICALREF        (int)     -- Birincil anahtar
OPERATIONREF      (int)     -- Operasyon ref. → LG_XXX_OPERTION.LOGICALREF
LINENO_           (int)     -- Satır numarası
PRIORITY          (int)     -- Öncelik

GROUP_            (int)     -- Kaynak türü:
                            --   0 = İş İstasyonu → WSREF'i LG_XXX_WORKSTAT'a bağla
                            --   1 = İş İstasyonu Grubu → WSREF'i LG_XXX_WSGRPF'ye bağla

WSREF             (int)     -- İş ist. / grup ref. (GROUP_'a göre farklı tablo)
BATCHQUANTITY     (float)   -- İşlem partisi
MINAMOUNT         (float)   -- Asgari miktar
MAXAMOUNT         (float)   -- Azami miktar

-- Süre alanları — TÜMÜ dbo.LG_INTTOTIME() ile gösterilmeli:
FIXEDSETUPTIME    (int)     -- Sabit hazırlık süresi
RUNTIME           (int)     -- İŞLEM SÜRESİ ← en kritik
TRANSBATCHTIME    (int)     -- Taşıma süresi
WAITBATCHTIME     (int)     -- Bekleme süresi
INSPTIME          (int)     -- Kontrol süresi
QUETIME           (int)     -- Kuyruk süresi
HEADTIME          (int)     -- Operasyon öncesi bekleme
TAILTIME          (int)     -- Operasyon sonrası bekleme

USAGEPER          (float)   -- İşgal % (ham değer, INTTOTIME gerekmez)
EFFICIENCY        (float)   -- Verim %
```

### İş İstasyonları — LG_XXX_WORKSTAT

```sql
LOGICALREF      (int)     -- Birincil anahtar
CODE            (varchar) -- İş istasyonu kodu
NAME            (varchar) -- İş istasyonu adı
ACTIVE          (int)     -- 0=Aktif
OPERATIONTIME   (float)   -- Günlük çalışma saati
HOURLYSTDCOST   (float)   -- Saatlik standart maliyet
CALENDARREF     (int)     -- Takvim ref.
CENTERREF       (int)     -- Maliyet merkezi ref.
```

---

## 17. İŞ EMİRLERİ — LG_XXX_DISPLINE

Firma bağımlı, **dönem bağımsız** (Level=1). `LG_XXX_YY_DISPLINE` değil, `LG_XXX_DISPLINE`.

Üretim emri çizelgelendiğinde, rotadaki her operasyon için DISPLINE'da bir satır oluşur. Bu satır = bir "iş emri".

```sql
LOGICALREF        (int)      -- Birincil anahtar
PRODORDREF        (int)      -- Üretim emri ref. → LG_XXX_PRODORD.LOGICALREF
LINENO_           (varchar)  -- İş emri satır numarası (string!)
ROUTLINEREF       (int)      -- Rota satır ref. → LG_XXX_RTNGLINE.LOGICALREF
OPERATIONREF      (int)      -- Operasyon ref. → LG_XXX_OPERTION.LOGICALREF
OPREQREF          (int)      -- Operasyon ihtiyacı ref. → LG_XXX_OPRTREQ.LOGICALREF
WSREF             (int)      -- İş istasyonu ref. → LG_XXX_WORKSTAT.LOGICALREF

WSDAILYOPTIME     (float)    -- İş ist. günlük çalışma saati (snapshot, çizelgeleme anındaki)
WSWORKINGDAYS     (int)      -- İş ist. çalışma günleri (snapshot)
SCHEDULED         (int)      -- 0=Çizelgelenmemiş, 1=Çizelgelenmiş
RELEASED          (int)      -- 0=Serbest bırakılmamış, 1=Serbest bırakılmış
LINESTATUS        (int)      -- Satır/iş emri durumu
QCOPOK            (int)      -- Kalite kontrol sonucu uygun mu (0/1)

-- Süre alanları — TÜMÜ dbo.LG_INTTOTIME() ile gösterilmeli:
RUNTIME           (int)      -- İŞLEM SÜRESİ ← en kritik
SETUPTIME         (int)      -- Kurulum süresi
QUEUETIME         (int)      -- Kuyruk süresi
MOVETIME          (int)      -- Taşıma süresi
INSPTIME          (int)      -- Kontrol süresi
HEADTIME          (int)      -- Öncesi bekleme
TAILTIME          (int)      -- Sonrası bekleme

RUNBATCH          (float)    -- İşlem partisi
MOVEBATCH         (float)    -- Taşıma partisi

-- Planlanan tarih/zaman (Longint → DATEADD dönüşümü):
OPBEGDATE         (int)      -- Planlanan başlangıç tarihi
OPBEGTIME         (int)      -- Planlanan başlangıç zamanı
OPDUEDATE         (int)      -- Planlanan bitiş tarihi
OPDUETIME         (int)      -- Planlanan bitiş zamanı
PLNDURATION       (float)    -- Planlanan süre

-- Gerçekleşen tarih/zaman:
ACTBEGDATE        (int)      -- Gerçekleşen başlangıç tarihi
ACTBEGTIME        (int)      -- Gerçekleşen başlangıç zamanı
ACTDUEDATE        (int)      -- Gerçekleşen bitiş tarihi
ACTDUETIME        (int)      -- Gerçekleşen bitiş zamanı
ACTDURATION       (float)    -- Gerçekleşen süre

-- Maliyet alanları:
STDWSCOST         (float)    -- Standart iş istasyonu maliyeti
STDLABORCOST      (float)    -- Standart işgücü maliyeti
STDTOTALCOST      (float)    -- Standart toplam maliyet
ACTWSCOST         (float)    -- Gerçekleşen iş ist. maliyeti
```

### Tarih Dönüşümü — DISPLINE

```sql
DATEADD(day, DISP.OPBEGDATE, '1899-12-30') AS PlanlananBaslangic,
DATEADD(day, DISP.OPDUEDATE, '1899-12-30') AS PlanlananBitis,
DATEADD(day, DISP.ACTBEGDATE, '1899-12-30') AS GercekBaslangic,
DATEADD(day, DISP.ACTDUEDATE, '1899-12-30') AS GercekBitis
```

---

## 18. LEVEL=0 TABLOLAR (FİRMA BAĞIMSIZ)

Bu tablolarda firma filtresi **`FIRMNR` alanıyla** yapılır, tablo adında firma numarası yoktur.

```sql
LG_SLSMAN       -- Satış elemanları
   LOGICALREF, CODE, DEFINITION_, FIRMNR

LG_SLSCLREL     -- Satış elemanı - Cari hesap ilişkisi
   SALESMANREF, CLIENTREF, FIRMNR

LG_CONTACTS     -- İlgili kişiler
   LOGICALREF, NAME, FIRMNR, CARDTYPE, CARDREF

LG_INDUSTRY     -- Sektörler
LG_OCCUPATION   -- Meslekler
LG_AVGCURRS     -- Ortalama kurlar
LG_WHLIST       -- Depo listesi

-- KULLANIM ÖRNEĞI:
FROM LG_SLSMAN SLS WITH (NOLOCK)
WHERE SLS.FIRMNR = 126
```

---

## 19. İLİŞKİ HARİTASI

Aşağıdaki ilişkiler tüm sorgularda rehber olarak kullanılır:

```
LG_XXX_ITEMS.LOGICALREF          ← STLINE.STOCKREF
LG_XXX_ITEMS.LOGICALREF          ← ORFLINE.STOCKREF
LG_XXX_ITEMS.LOGICALREF          ← PRODORD.ITEMREF
LG_XXX_ITEMS.LOGICALREF          ← INVDEF.ITEMREF

LG_XXX_CLCARD.LOGICALREF         ← INVOICE.CLIENTREF
LG_XXX_CLCARD.LOGICALREF         ← STFICHE.CLIENTREF
LG_XXX_CLCARD.LOGICALREF         ← STLINE.CLIENTREF
LG_XXX_CLCARD.LOGICALREF         ← ORFICHE.CLIENTREF

LG_XXX_YY_INVOICE.LOGICALREF     ← STLINE.INVOICEREF
LG_XXX_YY_STFICHE.LOGICALREF     ← STLINE.STFICHEREF
LG_XXX_YY_ORFICHE.LOGICALREF     ← ORFLINE.ORDFICHEREF

LG_XXX_PRODORD.LOGICALREF        ← STFICHE.PRODORDERREF
LG_XXX_PRODORD.LOGICALREF        ← DISPLINE.PRODORDREF

LG_XXX_OPERTION.LOGICALREF       ← OPRTREQ.OPERATIONREF
LG_XXX_OPERTION.LOGICALREF       ← DISPLINE.OPERATIONREF
LG_XXX_OPRTREQ.LOGICALREF        ← DISPLINE.OPREQREF
LG_XXX_WORKSTAT.LOGICALREF       ← DISPLINE.WSREF

L_CAPIWHOUSE.NR                  ← STFICHE.SOURCEINDEX
L_CAPIWHOUSE.NR                  ← INVOICE.SOURCEINDEX
LV_XXX_YY_GNTOTST.STOCKREF       ← ITEMS.LOGICALREF

L_CAPIUSER.NR                    ← CAPIBLOCK_CREATEDBY
L_CURRENCYLIST.CURTYPE           ← STLINE.TRCURR
```

---

## 20. STANDART SORGU ŞABLONLARI

### Şablon A — Fatura ve Satırları

```sql
-- CREATED BY: SLY  |  Date: YYYY-MM-DD
SELECT
    I.FICHENO            AS FaturaNo,
    I.DATE_              AS Tarih,
    C.CODE               AS CariKodu,
    C.DEFINITION_        AS CariAdi,
    IT.CODE              AS MalzemeKodu,
    IT.NAME              AS MalzemeAdi,
    L.AMOUNT             AS Miktar,
    L.PRICE              AS BirimFiyat,
    L.TOTAL              AS Tutar,
    L.LINENET            AS NetTutar
FROM LG_126_01_INVOICE I WITH (NOLOCK)
INNER JOIN LG_126_01_STLINE L WITH (NOLOCK)
    ON L.INVOICEREF = I.LOGICALREF
INNER JOIN LG_126_CLCARD C WITH (NOLOCK)
    ON C.LOGICALREF = I.CLIENTREF
INNER JOIN LG_126_ITEMS IT WITH (NOLOCK)
    ON IT.LOGICALREF = L.STOCKREF
WHERE I.ACTIVE = 0
    AND I.CANCELLED = 0
    AND I.TRCODE IN (7, 8)          -- Satış faturaları
    AND L.LINETYPE = 0              -- Malzeme satırları
    AND I.DATE_ >= '2024-01-01'
    AND I.DATE_ <= '2024-12-31'
ORDER BY I.DATE_, I.FICHENO
```

### Şablon B — İrsaliye ve Satırları

```sql
-- CREATED BY: SLY  |  Date: YYYY-MM-DD
SELECT
    F.FICHENO            AS IrsaliyeNo,
    F.DATE_              AS Tarih,
    C.DEFINITION_        AS CariAdi,
    IT.CODE              AS MalzemeKodu,
    IT.NAME              AS MalzemeAdi,
    L.AMOUNT             AS Miktar,
    WH.NAME              AS Ambar
FROM LG_126_01_STFICHE F WITH (NOLOCK)
INNER JOIN LG_126_01_STLINE L WITH (NOLOCK)
    ON L.STFICHEREF = F.LOGICALREF
INNER JOIN LG_126_CLCARD C WITH (NOLOCK)
    ON C.LOGICALREF = F.CLIENTREF
INNER JOIN LG_126_ITEMS IT WITH (NOLOCK)
    ON IT.LOGICALREF = L.STOCKREF
LEFT JOIN L_CAPIWHOUSE WH WITH (NOLOCK)
    ON WH.NR = F.SOURCEINDEX AND WH.FIRMNR = 126
WHERE F.ACTIVE = 0
    AND F.CANCELLED = 0
    AND F.TRCODE IN (1, 8)          -- Satınalma veya satış irsaliyesi
    AND L.LINETYPE = 0
ORDER BY F.DATE_, F.FICHENO
```

### Şablon C — Bekleyen Satış Siparişleri

```sql
-- CREATED BY: SLY  |  Date: YYYY-MM-DD
SELECT
    ORF.FICHENO                              AS SiparisNo,
    DATEADD(day, ORF.DATE_, '1899-12-30')   AS SiparisTarihi,
    C.DEFINITION_                            AS MusteriAdi,
    IT.CODE                                  AS MalzemeKodu,
    IT.NAME                                  AS MalzemeAdi,
    ORL.AMOUNT                               AS SiparisMiktari,
    ORL.SHIPPEDAMOUNT                        AS SevkEdilen,
    (ORL.AMOUNT - ORL.SHIPPEDAMOUNT)         AS Kalan,
    ORL.PRICE                                AS BirimFiyat
FROM LG_126_01_ORFICHE ORF WITH (NOLOCK)
INNER JOIN LG_126_01_ORFLINE ORL WITH (NOLOCK)
    ON ORL.ORDFICHEREF = ORF.LOGICALREF
INNER JOIN LG_126_CLCARD C WITH (NOLOCK)
    ON C.LOGICALREF = ORF.CLIENTREF
INNER JOIN LG_126_ITEMS IT WITH (NOLOCK)
    ON IT.LOGICALREF = ORL.STOCKREF
WHERE ORF.TRCODE = 1                          -- Satış siparişi
    AND ORF.STATUS = 3                        -- Sevkedilebilir/Onaylı
    AND ORF.CANCELLED = 0
    AND ORL.LINETYPE = 0
    AND ORL.CLOSED = 0
    AND (ORL.AMOUNT - ORL.SHIPPEDAMOUNT) > 0
ORDER BY ORF.DATE_, ORF.FICHENO
```

### Şablon D — Stok Durumu (Asgari Stok Kontrolü)

```sql
-- CREATED BY: SLY  |  Date: YYYY-MM-DD
SELECT
    IT.CODE                    AS MalzemeKodu,
    IT.NAME                    AS MalzemeAdi,
    SUM(ST.ONHAND)             AS FiiliStok,
    SUM(INV.MINLEVEL)          AS AsgariStok,
    SUM(ST.ONHAND)
    - SUM(INV.MINLEVEL)        AS Fark
FROM LG_126_ITEMS IT WITH (NOLOCK)
LEFT JOIN LV_126_01_GNTOTST ST WITH (NOLOCK)
    ON ST.STOCKREF = IT.LOGICALREF
    AND ST.INVENNO NOT IN (5, 6, 9)  -- Bloke ambarlar hariç (firma yapısına göre ayarlayın)
LEFT JOIN LG_126_INVDEF INV WITH (NOLOCK)
    ON INV.ITEMREF = IT.LOGICALREF
    AND INV.INVENNO NOT IN (5, 6, 9)
WHERE IT.ACTIVE = 0
    AND IT.CARDTYPE NOT IN (4, 20, 21)
GROUP BY IT.CODE, IT.NAME
HAVING SUM(ST.ONHAND) < SUM(INV.MINLEVEL)
ORDER BY Fark
```

### Şablon E — Üretim Emri Sarf Raporu

```sql
-- CREATED BY: SLY  |  Date: YYYY-MM-DD
;WITH SARF AS (
    SELECT
        SF.PRODORDERREF,
        SL.STOCKREF,
        SL.UOMREF,
        SUM(CASE WHEN SF.PRODSTAT = 1 THEN SL.AMOUNT ELSE 0 END) AS PlanlananSarf,
        SUM(CASE WHEN SF.PRODSTAT = 0 THEN SL.AMOUNT ELSE 0 END) AS GerceklesenSarf
    FROM LG_126_01_STFICHE SF WITH (NOLOCK)
    INNER JOIN LG_126_01_STLINE SL WITH (NOLOCK)
        ON SL.STFICHEREF = SF.LOGICALREF
        AND SL.LINETYPE = 0
    WHERE SF.TRCODE = 12              -- Sarf fişi
        AND SF.CANCELLED = 0
        AND SF.PRODORDERREF > 0       -- Üretim emrine bağlı
    GROUP BY SF.PRODORDERREF, SL.STOCKREF, SL.UOMREF
)
SELECT
    PROD.FICHENO                                    AS UretimEmriNo,
    DATEADD(day, PROD.DATE_, '1899-12-30')          AS UretimTarihi,
    MAMUL.CODE                                      AS MamulKodu,
    MAMUL.NAME                                      AS MamulAdi,
    PROD.PLNAMOUNT                                  AS PlanlananUretim,
    PROD.ACTAMOUNT                                  AS GerceklesenUretim,
    SARF_IT.CODE                                    AS SarfMalzemeKodu,
    SARF_IT.NAME                                    AS SarfMalzemeAdi,
    S.PlanlananSarf,
    S.GerceklesenSarf,
    (S.GerceklesenSarf - S.PlanlananSarf)           AS SarfSapma
FROM LG_126_PRODORD PROD WITH (NOLOCK)
INNER JOIN LG_126_ITEMS MAMUL WITH (NOLOCK)
    ON MAMUL.LOGICALREF = PROD.ITEMREF
LEFT JOIN SARF S
    ON S.PRODORDERREF = PROD.LOGICALREF
LEFT JOIN LG_126_ITEMS SARF_IT WITH (NOLOCK)
    ON SARF_IT.LOGICALREF = S.STOCKREF
WHERE PROD.CANCELLED = 0
ORDER BY PROD.FICHENO, SARF_IT.CODE
```

### Şablon F — İş Emri Operasyon Süresi

```sql
-- CREATED BY: SLY  |  Date: YYYY-MM-DD
SELECT
    PROD.FICHENO                                    AS UretimEmriNo,
    OPR.CODE                                        AS OperasyonKodu,
    OPR.NAME                                        AS OperasyonAdi,
    WS.CODE                                         AS IsIstasyonuKodu,
    WS.NAME                                         AS IsIstasyonuAdi,
    dbo.LG_INTTOTIME(DISP.RUNTIME)                  AS IslemSuresi,
    dbo.LG_INTTOTIME(DISP.SETUPTIME)                AS HazirlikSuresi,
    DATEADD(day, DISP.OPBEGDATE, '1899-12-30')      AS PlanlananBaslangic,
    DATEADD(day, DISP.OPDUEDATE, '1899-12-30')      AS PlanlananBitis,
    DATEADD(day, DISP.ACTBEGDATE, '1899-12-30')     AS GercekBaslangic,
    DATEADD(day, DISP.ACTDUEDATE, '1899-12-30')     AS GercekBitis,
    DISP.LINESTATUS                                 AS IsEmriDurumu
FROM LG_126_DISPLINE DISP WITH (NOLOCK)
INNER JOIN LG_126_PRODORD PROD WITH (NOLOCK)
    ON PROD.LOGICALREF = DISP.PRODORDREF
INNER JOIN LG_126_OPERTION OPR WITH (NOLOCK)
    ON OPR.LOGICALREF = DISP.OPERATIONREF
LEFT JOIN LG_126_WORKSTAT WS WITH (NOLOCK)
    ON WS.LOGICALREF = DISP.WSREF
WHERE PROD.CANCELLED = 0
ORDER BY PROD.FICHENO, DISP.LINENO_
```

---

## 21. PERFORMANS KURALLARI

Her rapor aşağıdaki performans ilkelerine uygun yazılmalıdır:

**WITH (NOLOCK):** Tüm tablolarda kullanılır. Canlı sistemde sorgu, üretim veya kullanıcı işlemlerini kilitlemez.

**Filtreyi erken uygula:** JOIN öncesinde mümkün olan filtreleri WHERE veya CTE içine alın. Büyük tablolarda (STLINE, STFICHE) TRCODE, CANCELLED gibi indeksli alanlarda filtre yapın.

**CTE ile ön agregasyon:** Büyük miktarda satır birleştirmeyi gerektiren sorgularda önce CTE içinde GROUP BY yapın, sonra ana sorguya katın. Bu yöntem FULL OUTER JOIN veya alt sorgu kullanımından daha hızlıdır.

**SELECT \* kullanmayın:** Sadece ihtiyaç duyulan alanları seçin. Özellikle STLINE (183 alan) gibi geniş tablolarda bellek tüketimini önemli ölçüde azaltır.

**INNER JOIN vs LEFT JOIN:** Varlığı kesin olmayan ilişkilerde LEFT JOIN kullanın (örn. her malzemenin ambar tanımı olmayabilir). Kesin ilişkilerde INNER JOIN daha hızlıdır.

```sql
-- İyi performans örneği:
;WITH AgregatCTE AS (
    SELECT STFICHEREF, STOCKREF,
           SUM(AMOUNT) AS ToplamMiktar
    FROM LG_126_01_STLINE WITH (NOLOCK)
    WHERE LINETYPE = 0
      AND TRCODE = 8
    GROUP BY STFICHEREF, STOCKREF
)
SELECT F.FICHENO, IT.CODE, CTE.ToplamMiktar
FROM LG_126_01_STFICHE F WITH (NOLOCK)
INNER JOIN AgregatCTE CTE ON CTE.STFICHEREF = F.LOGICALREF
INNER JOIN LG_126_ITEMS IT WITH (NOLOCK) ON IT.LOGICALREF = CTE.STOCKREF
WHERE F.CANCELLED = 0 AND F.TRCODE = 8
```

---

## 22. SIK YAPILAN HATALAR

### Hata 1 — STATUS = 2 Sevkedilebilir Sanmak

ORFICHE.STATUS = 2 "Sevkedilemez" demektir, "Sevkedilebilir" değil. Aktif bekleyen sipariş için `STATUS = 3` kullanılmalıdır.

### Hata 2 — PRODORD.STATUS ile ORFICHE.STATUS Karıştırmak

Aynı alan adı, tamamen farklı kod tabloları. PRODORD.STATUS = 2 "Durduruldu", ORFICHE.STATUS = 2 "Sevkedilemez". Aynı sorguda her ikisi varsa CTE ile ayırın ve yorum satırı bırakın.

### Hata 3 — LINETYPE Filtresi Unutmak

STLINE tablosunda malzeme, hizmet, masraf, iskonto satırları birlikte tutulur. Malzeme toplamı için `LINETYPE = 0` filtresi **her zaman** gereklidir.

### Hata 4 — ACTIVE Filtresi Unutmak

Pasif kayıtlar hareketlere dahil olmaya devam edebilir. `WHERE ACTIVE = 0` filtresi ihmal edilirse yanlış sonuçlar gelir.

### Hata 5 — Süre Alanlarında Aritmetik

`RUNTIME / 3600` gibi işlemler yanlış sonuç verir. Daima `dbo.LG_INTTOTIME(RUNTIME)` kullanın.

### Hata 6 — Level=0 Tablolarda FIRMNR Filtresi Unutmak

`LG_SLSMAN`, `L_CURRENCYLIST` gibi tablolarda `WHERE FIRMNR = 126` eklenmezse tüm firmaların verisi gelir ve JOIN'de satır patlar.

### Hata 7 — Tarih Dönüşümü

PRODORD, DISPLINE gibi tablolarda DATE_ alanı Longint formatındadır. `WHERE DATE_ >= '2024-01-01'` gibi doğrudan karşılaştırma yanlış sonuç verir. `DATEADD(day, DATE_, '1899-12-30')` ile dönüşüm yapın.

### Hata 8 — DISPLINE'ı Dönem Bağımlı Sanmak

`LG_XXX_DISPLINE` tablosu dönem bağımsızdır. `LG_XXX_YY_DISPLINE` diye bir tablo yoktur.

### Hata 9 — INVDEF.MINLEVELCTRL Alanına Güvenmek

Asgari stok raporlarında `MINLEVELCTRL` alanı dikkate alınmaz. Logo bu alanı tutarlı güncellemez. Sadece `MINLEVEL > 0` kontrolü yeterlidir.

### Hata 10 — Stok Miktarını ONHAND'den Rezerve Çıkarmadan "Kullanılabilir" Demek

`ONHAND` = Fiili Stok (rezerveler dahil). Kullanılabilir stok = `ONHAND - RESERVED`. Terminolojiyi doğru kullanın.

---

## 23. CARİ HESAP FİŞLERİ — LG_XXX_YY_CLFICHE & CLFLINE

Firma + dönem bağımlı (Level=2). Cari hesaba **tahsilat / ödeme / dekont / virman**
gibi para hareketlerini tutar. Fatura/irsaliye **dışındaki** cari hareketler buradadır.
`CLFICHE` = fiş başlığı, `CLFLINE` = fiş satırları (borç/alacak hareketleri).

### 23.1 Fiş Başlıkları — LG_XXX_YY_CLFICHE

```sql
LOGICALREF          (int)       -- Birincil anahtar
FICHENO             (varchar)   -- Fiş numarası
TRCODE              (int)       -- İşlem türü (aşağıya bakın) — raporda MUTLAKA filtrele
DATE_               (datetime)  -- Fiş tarihi
FTIME               (int)       -- Fiş saati (HHMMSS)
CLIENTREF           (int)       -- Cari hesap ref. → LG_XXX_CLCARD.LOGICALREF
ACCOUNTREF          (int)       -- Muhasebe hesap ref. (varsa)
ACTIVE              (int)       -- 0=Aktif, 1=Pasif
CANCELLED           (int)       -- 0=İptal değil, 1=İptal
MODULENR            (int)       -- Kaynak modül numarası
BRANCH              (int)       -- İşyeri numarası (firmaya göre zorunlu olabilir)
DEPARTMENT          (int)       -- Bölüm numarası (firmaya göre zorunlu olabilir)
DIVISION            (int)       -- Fabrika numarası
NETTOTAL            (float)     -- Fiş net toplamı
TOTALVAT            (float)     -- Toplam KDV (vade farkı/SMM fişlerinde)
TRCURR              (int)       -- İşlem dövizi türü → L_CURRENCYLIST
TRRATE              (float)     -- İşlem döviz kuru
REPORTRATE          (float)     -- Raporlama döviz kuru
GENEXP1..GENEXP6    (varchar)   -- Açıklama satırları
DOCODE              (varchar)   -- Belge numarası
CAPIBLOCK_CREADEDDATE   (datetime)  -- Oluşturulma tarihi
CAPIBLOCK_MODIFIEDDATE  (datetime)  -- Değiştirilme tarihi
```

### 23.2 Fiş Satırları — LG_XXX_YY_CLFLINE

```sql
LOGICALREF          (int)       -- Birincil anahtar
CLFICHEREF          (int)       -- Başlık ref. → CLFICHE.LOGICALREF
CLIENTREF           (int)       -- Cari hesap ref. → CLCARD.LOGICALREF
TRCODE              (int)       -- Satır işlem türü (başlıkla aynı)
DATE_               (datetime)  -- Hareket tarihi
MODULENR            (int)       -- Kaynak modül
SIGN                (int)       -- 0 = Borç, 1 = Alacak  ⚠️ tahsilat=alacak, ödeme=borç
TRANNO              (int)       -- Satır sıra no
AMOUNT              (float)     -- İşlem dövizi tutarı
TRRATE              (float)     -- Döviz kuru
LINEEXP             (varchar)   -- Satır açıklaması
```

### 23.3 TRCODE Değerleri — CLFICHE / CLFLINE  [DOĞRULANDI]

```
1  = Nakit Tahsilat            (alacak — saha satışçısı ana işlemi)
2  = Nakit Ödeme               (borç)
3  = Borç Dekontu
4  = Alacak Dekontu
5  = Virman İşlemi
6  = Kur Farkı İşlemi
12 = Özel İşlem
14 = Açılış İşlemi
41 = Verilen Vade Farkı Faturası
42 = Alınan Vade Farkı Faturası
45 = Verilen Serbest Meslek Makbuzu
46 = Alınan Serbest Meslek Makbuzu
70 = Kredi Kartı Fişi          (POS ile tahsilat — saha için anlamlı)
71 = Kredi Kartı İade Fişi
72 = Firma Kredi Kartı Fişi
73 = Firma Kredi Kartı İade Fişi
```

> **Saha tahsilat ekranı notu:** Satışçının fiilen keseceği türler pratikte
> `1` (Nakit Tahsilat) ve `70` (Kredi Kartı Fişi). `2` (Nakit Ödeme) opsiyonel.
> `3,4,5,6,12,14,41,42,45,46,71,72,73` muhasebe/merkez işlemleridir — saha
> ekranında gösterilmez (ileride yetki bazlı açılabilir).
>
> **Çek/senet bu listede yoktur** — onlar ayrı modüldür (banka/çek-senet bordrosu),
> CLFICHE'ye girmez. Saha tahsilatında çek alınacaksa ayrı ele alınmalı.

### 23.4 Zorunlu Alanlar — Statik Değil, Logo'dan Öğrenilir

Cari hesap fişinde **firmaya göre değişen** zorunluluklar vardır (BRANCH/DEPARTMENT
zorunlu mu, özel alanlar var mı). Bu yüzden tahsilat fişi yazımında zorunlu alanlar
**hardcode edilmez**; backend Logo REST'e probe (yoklama) yapıp dönen validation
hatasından öğrenir ve `GET /api/CollectionDraft/schema?trcode=N` ile Flutter'a bildirir.
Baseline (neredeyse her kurulumda ortak) zorunlu set: `TRCODE`, `CLIENTREF`,
`DATE_`, `AMOUNT`. Döviz default TL (`TRCURR=0`).

---

*Bu döküman Logo Tiger 3 Enterprise platformu için hazırlanmıştır. Firma numarası ve dönem numarası sorgularda dinamik olarak değiştirilmelidir. Canlı sistemde doğrulanmış bilgiler `[DOĞRULANDI]` notu ile işaretlenmiştir.*
