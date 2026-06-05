---
description: >
  Logo ERP veritabanı şeması referansı. Herhangi bir SQL sorgusu yazılmadan,
  Logo tablosuna bakılmadan, API endpoint'i veritabanına bağlanmadan ÖNCE
  LOGO_ERP_DATABASE_REFERENCE.md dosyasını oku. "Sorgu yaz", "tablodan çek",
  "Logo'dan veri al", "SELECT", "JOIN", "Logo ERP", "Logo Tiger", "Logo Go",
  "hangi tablo", "veritabanı" gibi ifadelerde her zaman önce bu dosyaya bak.
---

# Logo ERP Database Skill

Herhangi bir Logo ERP veritabanı işlemi yapılmadan önce bu prosedürü izle.

## Zorunlu İlk Adım

SQL sorgusu, tablo referansı veya Logo ERP verisi gereken her durumda:

1. Proje kökündeki `LOGO_ERP_DATABASE_REFERENCE.md` dosyasını oku
2. İlgili tablo ve kolon isimlerini doğrula
3. Ondan sonra sorguyu veya kodu yaz

Dosyayı okumadan tablo adı, kolon adı veya ilişki **tahmin etme**.

## Neden Önemli

Logo ERP tablolarının isimleri standart değil — Türkçe kısaltmalar, prefix'ler
ve sürüme göre farklılıklar içeriyor (Tiger, Go, Unity). Yanlış tablo adıyla
yazılmış kod runtime'da patlar. Her zaman dosyayı önce kontrol et.

## Sorgu Yazım Kuralları

Dosyayı okuduktan sonra:

- Tablo adlarını **tam olarak** dosyada göründüğü gibi yaz (büyük/küçük harf dahil)
- Kolon adlarını kısaltma — tam adını kullan
- JOIN yaparken ilişki dosyada belirtilmişse onu kullan, yoksa kullanıcıya sor
- Logo'nun computed/virtual kolonlarını direkt SELECT'e alma, önce kullanıcıya sor
- Tarih kolonları için Logo'nun kendi format yapısına dikkat et (dosyada belirtilmişse)
