import '../../core/services/app_launcher_service.dart';

class QRScannerService {
  Future<void> handleScannedCode(String code) async {
    try {
      if (code.isEmpty) {
        throw Exception('QR kod boş');
      }

      // URL'ler için
      if (code.startsWith('https://') || code.startsWith('http://')) {
        await AppLauncherService.launchWebURL(url: code);
        return;
      }

      // WhatsApp için telefon numarası
      if (code.startsWith('90') && RegExp(r'^\d{10,}$').hasMatch(code)) {
        await AppLauncherService.launchWhatsApp(phoneNumber: code);
        return;
      }

      // Varsayılan olarak web URL'si olarak aç
      await AppLauncherService.launchWebURL(url: code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openWhatsApp(String phoneNumber, {String countryCode = 'TR'}) async {
    try {
      if (phoneNumber.isEmpty) {
        throw Exception('Telefon numarası boş');
      }
      await AppLauncherService.launchWhatsApp(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openInstagram(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception('Kullanıcı adı boş');
      }
      await AppLauncherService.launchInstagram(username: username);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openX(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception('Kullanıcı adı boş');
      }
      await AppLauncherService.launchTwitter(username: username);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openDiscord(String inviteCode) async {
    try {
      if (inviteCode.isEmpty) {
        throw Exception('Davet kodu boş');
      }
      await AppLauncherService.launchDiscord(inviteCode: inviteCode);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('E-posta adresi boş');
      }
      await AppLauncherService.launchEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openTelegram(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception('Kullanıcı adı boş');
      }
      await AppLauncherService.launchTelegram(userIdOrUsername: username);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openSMS(String phoneNumber, [String message = '']) async {
    try {
      if (phoneNumber.isEmpty) {
        throw Exception('Telefon numarası boş');
      }
      await AppLauncherService.launchSMS(phoneNumber: phoneNumber, message: message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openFacebook(String pageId) async {
    try {
      if (pageId.isEmpty) {
        throw Exception('Sayfa ID boş');
      }
      await AppLauncherService.launchFacebook(pageIdOrUsername: pageId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openYouTube(String channelId) async {
    try {
      if (channelId.isEmpty) {
        throw Exception('Kanal ID boş');
      }
      await AppLauncherService.launchYouTube(channelIdOrUsername: channelId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openGitHub(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception('Kullanıcı adı boş');
      }
      await AppLauncherService.launchGitHub(username: username);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openLinkedIn(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception('Kullanıcı adı boş');
      }
      await AppLauncherService.launchLinkedIn(username: username);
    } catch (e) {
      rethrow;
    }
  }
}