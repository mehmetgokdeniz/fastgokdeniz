# mobilapptry

`mobilapptry`, QR kod tarama, paylaşma ve yönlendirme özellikleri sunan gelişmiş bir Flutter mobil uygulamasıdır. Uygulama, Android ve iOS platformları için hazırdır, Firebase, yerel veritabanı, paylaşım, bildirim ve kapsamlı QR işleme özellikleri içerir.

## 🚀 Proje Hakkında

Bu proje, QR kod tarama, özel mesaj ve bağlantı yönlendirme, sosyal medya entegrasyonları ve kullanıcı verilerini yönetme özelliklerini bir arada sunar. Hem yerel depolama hem de bulut tabanlı servislerle çalışmak üzere tasarlanmıştır.

## ✨ Temel Özellikler

- QR kod tarama ve geçmiş kaydı
- WhatsApp, Telegram, Discord, Instagram, Facebook, YouTube, Twitter/X yönlendirme
- Email, SMS ve telefon arama desteği
- Paylaşma ve dışa aktarma seçenekleri
- Gelişmiş filtreleme ve arama seçenekleri
- Favori kayıtları ve istatistik takibi
- Firebase Authentication ve veri depolama altyapısı
- Yerel veritabanı ve cache yönetimi
- Bildirimler ve kullanıcı ayarları

## 🧩 Teknoloji Yığını

- Flutter 3.x
- Dart 3.x
- Provider
- url_launcher
- qr_flutter
- mobile_scanner
- shared_preferences
- hive / hive_flutter
- google_mlkit_barcode_scanning
- dio
- connectivity_plus
- image_picker
- flutter_svg
- path_provider

## 📁 Proje Yapısı

```
mobilapptry/
├── android/
├── ios/
├── lib/
│   ├── core/
│   │   ├── enums/
│   │   └── services/
│   ├── data/
│   │   ├── models/
│   │   └── services/
│   ├── presentation/
│   │   └── providers/
│   └── view/
│       └── screens/
├── test/
├── .github/
│   └── workflows/
├── pubspec.yaml
└── README.md
```

## ⚙️ Hazırlık ve Çalıştırma

### Gereksinimler

- Flutter SDK
- Android Studio veya VS Code
- `flutter pub get`
- `flutter pub run build_runner build`

### Adım 1: Bağımlılıkları Yükleyin

```bash
cd mobilapptry
flutter pub get
```

### Adım 2: Build Runner Çalıştırın

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Adım 3: Uygulamayı Çalıştırın

```bash
flutter run
```

## 📱 Firebase Kurulumu

Bu proje Firebase entegrasyonu kullanır ve Firebase servisleri için gizli dosyaların GitHub'a eklenmemesi gerekir.

### Firebase Dosyaları GitHub'a Eklenmeyecek

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### Firebase Hazırlık Notları

1. Firebase Console üzerinden yeni bir proje oluşturun.
2. Android için paket adını `com.example.mobilapptry` olarak kontrol edin.
3. `google-services.json` dosyasını `android/app/` içine yerleştirin.
4. iOS için `GoogleService-Info.plist` dosyasını `ios/Runner/` içine yerleştirin.
5. Authentication > Email/Password ve gerekirse Anonymous sign-in etkinleştirin.

## 🧪 Test ve Build Komutları

### Android cihazda çalıştırma

```bash
flutter run
```

### iOS cihazda çalıştırma (macOS)

```bash
flutter run
```

### Release derleme

```bash
flutter build apk --release
flutter build ios --release
```

## 🛠️ GitHub Actions

Bu proje `.github/workflows/ios_build.yml` ile iOS için IPA oluşturma yeteneğine sahiptir. Workflow, `main` ve `develop` dallarına yapılan pushlarda ya da pull requestlerde çalışır.

## 📝 Kod ve Özellik Özetleri

### Çekirdek Servisler

- `lib/core/services/app_launcher_service.dart`: WhatsApp, Telegram, Discord, Instagram, Facebook, YouTube, SMS, Email, Telefon araması ve web yönlendirmelerini yönetir.
- `lib/core/services/search_filter_service.dart`: Gelişmiş arama ve filtreleme.
- `lib/core/services/sharing_service.dart`: Paylaşma ve dışa aktarma.

### Veri Modelleri

- `lib/data/models/scan_history.dart`
- `lib/data/models/user_profile.dart`
- `lib/data/models/saved_message.dart`
- `lib/data/models/cache_item.dart`

### UI Katmanı

- `lib/view/screens/home_screen.dart`
- `lib/view/screens/login_screen.dart`
- `lib/view/screens/profile_detail_screen.dart`
- `lib/view/screens/favorites_screen.dart`
- `lib/view/screens/advanced_search_screen.dart`
- `lib/view/screens/settings_advanced_screen.dart`

## ✅ GitHub Hazırlıkları Tamamlandı

- `README.md` projenin tamamını ve kurulumu detaylıca açıklayacak şekilde güncellendi.
- `.gitignore` Firebase ve yerel gizli yapılandırma dosyaları için genişletildi.

## 💡 Notlar

- `build/` klasörü zaten `.gitignore` tarafından yoksayılıyor.
- `google-services.json` ve `GoogleService-Info.plist` dosyaları kesinlikle sürüm kontrolüne eklenmemelidir.
- `flutter pub get` ve `build_runner` komutları çalıştırıldıktan sonra proje GitHub'a gönderilebilir.

## 📌 İlerleyen Adımlar

1. Yerel geliştirme ortamınızda `flutter pub get` çalıştırın.
2. `flutter pub run build_runner build --delete-conflicting-outputs` çalıştırın.
3. Firebase dosyalarınızı yerel olarak ekleyin, ama bunları commitlemeyin.
4. Değişiklikleri git ile takip edip GitHub'a pushlayın.


## Ekran Görüntüleri

| Giriş Ekranı | Ana Sayfa | Profil Sayfası |
| :---: | :---: | :---: |
| <img src="https://i.hizliresim.com/dqxfqh3.jpeg" width="200"> | <img src="resim_linki_2" width="200"> | <img src="resim_linki_3" width="200"> |
