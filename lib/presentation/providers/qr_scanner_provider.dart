import 'package:flutter/material.dart';
import '../../core/services/app_launcher_service.dart';
import '../../data/services/qr_scanner_service.dart';

class QRScannerProvider with ChangeNotifier {
  final QRScannerService _qrScannerService;

  QRScannerProvider(this._qrScannerService);

  String _scannedCode = '';
  bool _isProcessing = false;

  String get scannedCode => _scannedCode;
  bool get isProcessing => _isProcessing;

  void setScannedCode(String code) {
    _scannedCode = code;
    notifyListeners();
  }

  Future<void> handleScannedCode(String code) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _qrScannerService.handleScannedCode(code);
      _scannedCode = code;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> openWhatsApp(
    String phoneNumber, {
    String countryCode = 'TR',
  }) async {
    try {
      await _qrScannerService.openWhatsApp(
        phoneNumber,
        countryCode: countryCode,
      );
    } catch (e) {
      throw Exception('WhatsApp açılamadı: $e');
    }
  }

  Future<void> openInstagram(String username) async {
    try {
      await _qrScannerService.openInstagram(username);
    } catch (e) {
      throw Exception('Instagram açılamadı: $e');
    }
  }

  Future<void> openX(String username) async {
    try {
      await _qrScannerService.openX(username);
    } catch (e) {
      throw Exception('X (Twitter) açılamadı: $e');
    }
  }

  Future<void> openDiscord(String userId) async {
    try {
      await _qrScannerService.openDiscord(userId);
    } catch (e) {
      throw Exception('Discord açılamadı: $e');
    }
  }

  Future<void> openEmail(String email) async {
    try {
      await _qrScannerService.openEmail(email);
    } catch (e) {
      throw Exception('Email açılamadı: $e');
    }
  }

  Future<void> openTelegram(String username) async {
    try {
      await _qrScannerService.openTelegram(username);
    } catch (e) {
      throw Exception('Telegram açılamadı: $e');
    }
  }

  /// SMS/Mobile message gönder (Android 11+ uyumlu)
  Future<void> openSMS(String phoneNumber, [String message = '']) async {
    try {
      await _qrScannerService.openSMS(phoneNumber, message);
    } catch (e) {
      throw Exception('SMS açılamadı: $e');
    }
  }

  /// Facebook sayfasını aç
  Future<void> openFacebook(String pageId) async {
    try {
      await _qrScannerService.openFacebook(pageId);
    } catch (e) {
      throw Exception('Facebook açılamadı: $e');
    }
  }

  /// YouTube kanalını aç
  Future<void> openYouTube(String channelId) async {
    try {
      await _qrScannerService.openYouTube(channelId);
    } catch (e) {
      throw Exception('YouTube açılamadı: $e');
    }
  }

  /// GitHub profilini aç
  Future<void> openGitHub(String username) async {
    try {
      await AppLauncherService.launchGitHub(username: username);
    } catch (e) {
      throw Exception('GitHub açılamadı: $e');
    }
  }

  /// LinkedIn profilini aç
  Future<void> openLinkedIn(String username) async {
    try {
      await AppLauncherService.launchLinkedIn(username: username);
    } catch (e) {
      throw Exception('LinkedIn açılamadı: $e');
    }
  }

  /// Telefon ara
  Future<void> openPhoneCall(String phoneNumber) async {
    try {
      await AppLauncherService.launchPhoneCall(phoneNumber: phoneNumber);
    } catch (e) {
      throw Exception('Telefon araması yapılamadı: $e');
    }
  }

  /// Web URL aç
  Future<void> launchWebURL(String url) async {
    try {
      await AppLauncherService.launchWebURL(url: url);
    } catch (e) {
      throw Exception('URL açılamadı: $e');
    }
  }
}
