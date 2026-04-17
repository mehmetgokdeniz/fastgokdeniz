import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/enums/message_type.dart';
import '../../presentation/providers/message_provider.dart';
import '../../presentation/providers/theme_provider.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  static const List<Map<String, dynamic>> countryCodes = [
    {
      'code': '+90',
      'flag': '🇹🇷',
      'name': 'Türkiye',
      'example': '555 123 45 67',
    },
    {
      'code': '+1',
      'flag': '🇺🇸',
      'name': 'United States',
      'example': '(555) 123-4567',
    },
    {
      'code': '+44',
      'flag': '🇬🇧',
      'name': 'United Kingdom',
      'example': '07123 456789',
    },
    {
      'code': '+49',
      'flag': '🇩🇪',
      'name': 'Deutschland',
      'example': '151 12345678',
    },
    {
      'code': '+33',
      'flag': '🇫🇷',
      'name': 'France',
      'example': '06 12 34 56 78',
    },
    {'code': '+34', 'flag': '🇪🇸', 'name': 'España', 'example': '612 345 678'},
    {
      'code': '+39',
      'flag': '🇮🇹',
      'name': 'Italia',
      'example': '312 345 6789',
    },
    {
      'code': '+31',
      'flag': '🇳🇱',
      'name': 'Nederland',
      'example': '06 12345678',
    },
    {
      'code': '+32',
      'flag': '🇧🇪',
      'name': 'Belgique',
      'example': '0471 23 45 67',
    },
    {
      'code': '+41',
      'flag': '🇨🇭',
      'name': 'Schweiz',
      'example': '079 123 45 67',
    },
    {
      'code': '+43',
      'flag': '🇦🇹',
      'name': 'Österreich',
      'example': '0664 12345678',
    },
    {
      'code': '+46',
      'flag': '🇸🇪',
      'name': 'Sverige',
      'example': '070 123 45 67',
    },
    {'code': '+47', 'flag': '🇳🇴', 'name': 'Norge', 'example': '412 34 567'},
    {
      'code': '+45',
      'flag': '🇩🇰',
      'name': 'Danmark',
      'example': '20 12 34 56',
    },
    {
      'code': '+358',
      'flag': '🇫🇮',
      'name': 'Suomi',
      'example': '040 123 4567',
    },
    {'code': '+48', 'flag': '🇵🇱', 'name': 'Polska', 'example': '512 345 678'},
    {
      'code': '+7',
      'flag': '🇷🇺',
      'name': 'Россия',
      'example': '912 345-67-89',
    },
    {
      'code': '+380',
      'flag': '🇺🇦',
      'name': 'Україна',
      'example': '050 123 45 67',
    },
    {'code': '+98', 'flag': '🇮🇷', 'name': 'ایران', 'example': '912 345 6789'},
    {
      'code': '+966',
      'flag': '🇸🇦',
      'name': 'المملكة',
      'example': '50 123 4567',
    },
    {
      'code': '+971',
      'flag': '🇦🇪',
      'name': 'الإمارات',
      'example': '50 123 4567',
    },
    {'code': '+20', 'flag': '🇪🇬', 'name': 'مصر', 'example': '10 123 4567'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India', 'example': '98765 43210'},
    {
      'code': '+92',
      'flag': '🇵🇰',
      'name': 'Pakistan',
      'example': '300 1234567',
    },
    {
      'code': '+880',
      'flag': '🇧🇩',
      'name': 'Bangladesh',
      'example': '01712 345678',
    },
    {'code': '+86', 'flag': '🇨🇳', 'name': '中国', 'example': '138 0013 8000'},
    {'code': '+81', 'flag': '🇯🇵', 'name': '日本', 'example': '090 1234 5678'},
    {'code': '+82', 'flag': '🇰🇷', 'name': '한국', 'example': '010-1234-5678'},
    {'code': '+886', 'flag': '🇹🇼', 'name': '台灣', 'example': '0912 345 678'},
    {'code': '+66', 'flag': '🇹🇭', 'name': 'ไทย', 'example': '081 234 5678'},
    {
      'code': '+84',
      'flag': '🇻🇳',
      'name': 'Việt Nam',
      'example': '091 234 5678',
    },
    {
      'code': '+60',
      'flag': '🇲🇾',
      'name': 'Malaysia',
      'example': '012 345 6789',
    },
    {
      'code': '+65',
      'flag': '🇸🇬',
      'name': 'Singapore',
      'example': '8123 4567',
    },
    {
      'code': '+62',
      'flag': '🇮🇩',
      'name': 'Indonesia',
      'example': '0812 3456 789',
    },
    {
      'code': '+63',
      'flag': '🇵🇭',
      'name': 'Philippines',
      'example': '0917 123 4567',
    },
    {
      'code': '+61',
      'flag': '🇦🇺',
      'name': 'Australia',
      'example': '0412 345 678',
    },
    {
      'code': '+64',
      'flag': '🇳🇿',
      'name': 'New Zealand',
      'example': '021 123 4567',
    },
    {
      'code': '+55',
      'flag': '🇧🇷',
      'name': 'Brasil',
      'example': '(11) 91234-5678',
    },
    {
      'code': '+52',
      'flag': '🇲🇽',
      'name': 'México',
      'example': '55 1234 5678',
    },
    {
      'code': '+54',
      'flag': '🇦🇷',
      'name': 'Argentina',
      'example': '11 2345-6789',
    },
    {
      'code': '+1',
      'flag': '🇨🇦',
      'name': 'Canada',
      'example': '(416) 123-4567',
    },
    {
      'code': '+27',
      'flag': '🇿🇦',
      'name': 'South Africa',
      'example': '071 123 4567',
    },
    {
      'code': '+234',
      'flag': '🇳🇬',
      'name': 'Nigeria',
      'example': '0803 123 4567',
    },
    {
      'code': '+225',
      'flag': '🇨🇮',
      'name': 'Cote d\'Ivoire',
      'example': '07 12 34 56 78',
    },
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya', 'example': '0712 345678'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);
    final language = context.read<ThemeProvider>().language;
    final messageScreenTitle = AppStrings.get('messageScreenTitle', language);
    final platformSelect = AppStrings.get('platformSelect', language);

    return Scaffold(
      appBar: AppBar(
        title: Text(messageScreenTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platformSelect,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MessageType>(
                initialValue: provider.selectedType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.chat),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: MessageType.values.map((type) {
                  String displayText;
                  switch (type) {
                    case MessageType.whatsapp:
                      displayText = '💬 WhatsApp';
                      break;
                    case MessageType.telegram:
                      displayText = '✈️ Telegram';
                      break;
                    case MessageType.sms:
                      displayText = '📱 SMS';
                      break;
                    case MessageType.email:
                      displayText = '📧 Email';
                      break;
                    case MessageType.instagram:
                      displayText = '📸 Instagram';
                      break;
                    case MessageType.facebook:
                      displayText = '👥 Facebook';
                      break;
                    case MessageType.x:
                      displayText = '🐦 X (Twitter)';
                      break;
                    case MessageType.discord:
                      displayText = '🎮 Discord';
                      break;
                    case MessageType.youtube:
                      displayText = '📺 YouTube';
                      break;
                    case MessageType.github:
                      displayText = '💻 GitHub';
                      break;
                    case MessageType.linkedin:
                      displayText = '💼 LinkedIn';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) provider.setSelectedType(value);
                },
              ),
              const SizedBox(height: 24),
              // Ülke kodu ve telefon numarası sadece telefon gerektiren platformlar için
              if (provider.selectedType != MessageType.github &&
                  provider.selectedType != MessageType.linkedin &&
                  provider.selectedType != MessageType.instagram &&
                  provider.selectedType != MessageType.facebook &&
                  provider.selectedType != MessageType.x &&
                  provider.selectedType != MessageType.discord &&
                  provider.selectedType != MessageType.youtube)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ülke Kodu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: provider.selectedCountryCode,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.flag),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: countryCodes.map((country) {
                        return DropdownMenuItem<String>(
                          value: country['code'],
                          child: Row(
                            children: [
                              Text(
                                country['flag']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text('${country['code']} - ${country['name']}'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) provider.setCountryCode(value);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Telefon Numarası',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Örn: 5551234567',
                        prefixIcon: const Icon(Icons.phone),
                        hintText: 'Ülke kodu olmadan girin',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: provider.setPhoneNumber,
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kullanıcı Adı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: provider.selectedType == MessageType.github
                            ? 'GitHub kullanıcı adı'
                            : provider.selectedType == MessageType.linkedin
                            ? 'LinkedIn kullanıcı adı'
                            : provider.selectedType == MessageType.instagram
                            ? 'Instagram kullanıcı adı'
                            : provider.selectedType == MessageType.facebook
                            ? 'Facebook kullanıcı adı/ID'
                            : provider.selectedType == MessageType.x
                            ? 'X (Twitter) kullanıcı adı'
                            : provider.selectedType == MessageType.discord
                            ? 'Discord kullanıcı adı'
                            : 'YouTube kullanıcı adı/Kanal ID',
                        prefixIcon: const Icon(Icons.person),
                        hintText: 'Kullanıcı adınızı girin',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: provider
                          .setPhoneNumber, // Aynı fonksiyonu kullanıyoruz
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const Text(
                'Mesaj (İsteğe bağlı)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Gönderilecek mesaj',
                  prefixIcon: const Icon(Icons.message),
                  hintText: 'Mesajınızı yazın (boş bırakabilirsiniz)',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                onChanged: provider.setMessage,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await provider.sendMessage();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            '✅ Uygulamayı açtığımız için başarılı!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('❌ Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Gönder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
