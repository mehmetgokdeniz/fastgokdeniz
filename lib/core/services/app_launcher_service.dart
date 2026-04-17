import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppLauncherService {
  static final Connectivity _connectivity = Connectivity();

  /// İnternet bağlantı kontrolü
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // result artık List<ConnectivityResult> değil, ConnectivityResult
      // Web'de farklı response.
      if (result is List) {
        return !(result as List<dynamic>).contains(ConnectivityResult.none);
      } else {
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  /// Ülke kodları haritası
  static const Map<String, String> countryCodes = {
    'TR': '90',
    'US': '1',
    'UK': '44',
    'DE': '49',
    'FR': '33',
    'ES': '34',
    'IT': '39',
    'NL': '31',
    'BE': '32',
    'CH': '41',
    'AT': '43',
    'SE': '46',
    'NO': '47',
    'DK': '45',
    'FI': '358',
    'PL': '48',
    'CZ': '420',
    'HU': '36',
    'RO': '40',
    'GR': '30',
    'PT': '351',
    'UA': '380',
    'RU': '7',
    'KZ': '7',
    'KG': '996',
    'UZ': '998',
    'TM': '993',
    'AZ': '994',
    'AM': '374',
    'ME': '382',
    'RS': '381',
    'HR': '385',
    'BIH': '387',
    'MK': '389',
    'AL': '355',
    'GE': '995',
    'IR': '98',
    'IQ': '964',
    'SA': '966',
    'AE': '971',
    'KW': '965',
    'QA': '974',
    'BH': '973',
    'OM': '968',
    'YE': '967',
    'JO': '962',
    'LB': '961',
    'SY': '963',
    'PS': '970',
    'IL': '972',
    'EG': '20',
    'LY': '218',
    'TN': '216',
    'DZ': '213',
    'MA': '212',
    'SD': '249',
    'ET': '251',
    'IN': '91',
    'PK': '92',
    'BD': '880',
    'LK': '94',
    'NP': '977',
    'BT': '975',
    'MM': '95',
    'TH': '66',
    'LA': '856',
    'KH': '855',
    'VN': '84',
    'MY': '60',
    'SG': '65',
    'ID': '62',
    'PH': '63',
    'TW': '886',
    'CN': '86',
    'JP': '81',
    'KR': '82',
    'HK': '852',
    'MO': '853',
    'AU': '61',
    'NZ': '64',
    'FJ': '679',
    'PG': '675',
    'SB': '677',
    'VU': '678',
    'WS': '685',
    'KI': '686',
    'TO': '676',
    'PW': '680',
    'FM': '691',
    'MH': '692',
    'ZA': '27',
    'KE': '254',
    'UG': '256',
    'TZ': '255',
    'ZW': '263',
    'ZM': '260',
    'MW': '265',
    'MZ': '258',
    'AO': '244',
    'GH': '233',
    'NG': '234',
    'CM': '237',
    'CI': '225',
    'SN': '221',
    'MG': '261',
    'MU': '230',
    'SC': '248',
    'BR': '55',
    'AR': '54',
    'CL': '56',
    'CO': '57',
    'VE': '58',
    'PE': '51',
    'EC': '593',
    'BO': '591',
    'PY': '595',
    'UY': '598',
    'MX': '52',
    'GT': '502',
    'HN': '504',
    'SV': '503',
    'NI': '505',
    'CR': '506',
    'PA': '507',
    'CU': '53',
    'DO': '1', // Dominican Republic
    'JM': '1', // Jamaica
    'TT': '1', // Trinidad
    'BS': '1', // Bahamas
    'BB': '1', // Barbados
    'LC': '1', // Saint Lucia
    'VC': '1', // Saint Vincent
    'AG': '1', // Antigua and Barbuda
    'DM': '1', // Dominica
    'BZ': '501',
    'CA': '1',
  };

  /// WhatsApp'a mesaj gönder (ülke kodu destekli)
  static Future<void> launchWhatsApp({
    required String phoneNumber,
    String message = '',
    String countryCode = 'TR', // Varsayılan Türkiye
  }) async {
    try {
      // Numarayı temizle
      String phone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Seçilen ülkenin telefon kodunu al
      String dialCode = countryCodes[countryCode.toUpperCase()] ?? '90';

      // Eğer prefix varsa kaldır
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }

      // Telefon numarasının başına ülke kodu ekle
      if (!phone.startsWith(dialCode)) {
        phone = '$dialCode$phone';
      }

      phone = '+$phone';

      final String whatsappUrl =
          'https://wa.me/$phone${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('WhatsApp açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Telegram'da sohbet aç
  static Future<void> launchTelegram({required String userIdOrUsername}) async {
    try {
      // Username ise @ ile başlarsa kaldır
      String username = userIdOrUsername.startsWith('@')
          ? userIdOrUsername.substring(1)
          : userIdOrUsername;

      final String url = 'https://t.me/$username';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Telegram açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Discord'a katıl veya mesaj gönder
  static Future<void> launchDiscord({required String inviteCode}) async {
    try {
      // Invite code'dan parametreleri temizle
      String code = inviteCode.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
      final String discordUrl = 'https://discord.gg/$code';

      if (await canLaunchUrl(Uri.parse(discordUrl))) {
        await launchUrl(
          Uri.parse(discordUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Discord açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Instagram'ı aç veya profil ziyaret et
  static Future<void> launchInstagram({required String username}) async {
    try {
      // Username'den @ varsa kaldır
      String user = username.startsWith('@') ? username.substring(1) : username;

      final String instagramUrl = 'https://www.instagram.com/$user/';

      if (await canLaunchUrl(Uri.parse(instagramUrl))) {
        await launchUrl(
          Uri.parse(instagramUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Instagram açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Email gönder
  static Future<void> launchEmail({
    required String email,
    String subject = '',
    String body = '',
  }) async {
    try {
      final String emailUrl = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          if (subject.isNotEmpty) 'subject': subject,
          if (body.isNotEmpty) 'body': body,
        },
      ).toString();

      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('E-posta uygulaması bulunamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// SMS/Text mesaj gönder (Mobile)
  static Future<void> launchSMS({
    required String phoneNumber,
    String message = '',
  }) async {
    try {
      // Numarayı temizle
      String phone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final String smsUrl = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {if (message.isNotEmpty) 'body': message},
      ).toString();

      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(
          Uri.parse(smsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('SMS uygulaması bulunamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Web linki aç
  static Future<void> launchWebURL({required String url}) async {
    try {
      // İnternet kontrolü
      if (!(await hasInternetConnection())) {
        throw Exception(
          'İnternet bağlantısı bulunamadı. Lütfen internet bağlantınızı kontrol edin.',
        );
      }

      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Web linki açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GitHub profilini aç
  static Future<void> launchGitHub({required String username}) async {
    try {
      String user = username.startsWith('@') ? username.substring(1) : username;
      user = user.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
      final String githubUrl = 'https://github.com/$user';

      if (await canLaunchUrl(Uri.parse(githubUrl))) {
        await launchUrl(Uri.parse(githubUrl), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('GitHub açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Telefon ara
  static Future<void> launchPhoneCall({required String phoneNumber}) async {
    try {
      // Numarayı temizle
      String phone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final phoneUrl = 'tel:$phone';

      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(
          Uri.parse(phoneUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Telefon araması yapılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Facebook'u aç
  static Future<void> launchFacebook({required String pageIdOrUsername}) async {
    try {
      String page = pageIdOrUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '');
      final String facebookUrl = 'https://www.facebook.com/$page';

      if (await canLaunchUrl(Uri.parse(facebookUrl))) {
        await launchUrl(
          Uri.parse(facebookUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Facebook açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// YouTube kanalını aç
  static Future<void> launchYouTube({
    required String channelIdOrUsername,
  }) async {
    try {
      String channel = channelIdOrUsername.startsWith('@')
          ? channelIdOrUsername
          : '@${channelIdOrUsername.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '')}';

      final String youtubeUrl = 'https://www.youtube.com/$channel';

      if (await canLaunchUrl(Uri.parse(youtubeUrl))) {
        await launchUrl(
          Uri.parse(youtubeUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('YouTube açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// LinkedIn profilini aç
  static Future<void> launchLinkedIn({required String username}) async {
    try {
      String user = username.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      final String linkedinUrl = 'https://www.linkedin.com/in/$user';

      if (await canLaunchUrl(Uri.parse(linkedinUrl))) {
        await launchUrl(
          Uri.parse(linkedinUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('LinkedIn açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Twitter/X profilini aç
  static Future<void> launchTwitter({required String username}) async {
    try {
      String user = username.startsWith('@') ? username.substring(1) : username;
      user = user.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

      final String twitterUrl = 'https://twitter.com/$user';

      if (await canLaunchUrl(Uri.parse(twitterUrl))) {
        await launchUrl(
          Uri.parse(twitterUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Twitter/X açılamadı');
      }
    } catch (e) {
      rethrow;
    }
  }
}
