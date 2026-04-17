# FastGokdeniz v1.0.0.2

Repository: https://github.com/mehmetgokdeniz/fastgokdeniz

## Degisiklik Ozeti

Bu surum QR tarayici kararliligini artirmaya odaklanmistir.

- QR tarayici sekme gecis hatasi duzeltildi.
  - "QR kodu tara -> QR olusturucu -> tekrar QR kodu tara" akisinda gorulen kamera unlem hatasi giderildi.
- Scanner controller yonetimi ekran bazli hale getirildi.
  - Global/singleton state kaynakli kamera kilitlenmeleri azaltildi.
- Kamera yasam dongusu iyilestirildi.
  - Sekmeye giriste guvenli start, sekmeden cikista guvenli stop akisi uygulandi.
  - Live detection sonrasi yanlis zamanda yeniden baslatma yarisi engellendi.
- URL acma akisi iyilestirildi.
  - Schemasiz baglantilar icin otomatik https eklendi.
  - Bosluk/format kaynakli parse problemlerine karsi normalize edildi.
  - Gecersiz veya acilamayan URL durumlarinda kullaniciya acik mesajlar eklendi.
- QR tarayici metinleri guncellendi.
  - Yeni URL hata mesajlari TR/EN/AR ve coklu dil fallback kapsaminda eklendi.

## Surum Bilgisi

- Uygulama ici surum etiketi: v1.0.0.2
- Paket surumu: 1.0.0+2
