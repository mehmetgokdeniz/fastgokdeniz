import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../data/services/app_storage_service.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/qr_scanner_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppStorageService _storageService = AppStorageService();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _socialController = TextEditingController();
  final TextEditingController _toolController = TextEditingController();

  late Future<_HomeSeedData> _seedFuture;
  int _selectedTab = 0;
  int _selectedSocialIndex = 0;
  int _selectedChatIndex = 0;
  int _selectedToolIndex = 0;
  String _selectedCountryIso = 'TR';

  static final RegExp _historyPrefixPattern = RegExp(
    r'^(WA:|SMS:|TG:|Signal:|Viber:|LINE:|Messenger:|Discord:|Instagram:|X:|Snapchat:|YouTube:|TikTok:|Twitch:|Facebook:|Kick:|LinkedIn:|Email: )',
  );

  static const List<_CountryOption> _countryOptions = [
    _CountryOption(iso: 'TR', dialCode: '90', flag: '🇹🇷', name: 'Turkiye'),
    _CountryOption(iso: 'DE', dialCode: '49', flag: '🇩🇪', name: 'Germany'),
    _CountryOption(iso: 'SE', dialCode: '46', flag: '🇸🇪', name: 'Sweden'),
    _CountryOption(iso: 'NO', dialCode: '47', flag: '🇳🇴', name: 'Norway'),
    _CountryOption(iso: 'DK', dialCode: '45', flag: '🇩🇰', name: 'Denmark'),
    _CountryOption(iso: 'FI', dialCode: '358', flag: '🇫🇮', name: 'Finland'),
    _CountryOption(
      iso: 'NL',
      dialCode: '31',
      flag: '🇳🇱',
      name: 'Netherlands',
    ),
    _CountryOption(iso: 'BE', dialCode: '32', flag: '🇧🇪', name: 'Belgium'),
    _CountryOption(iso: 'FR', dialCode: '33', flag: '🇫🇷', name: 'France'),
    _CountryOption(iso: 'IT', dialCode: '39', flag: '🇮🇹', name: 'Italy'),
    _CountryOption(iso: 'ES', dialCode: '34', flag: '🇪🇸', name: 'Spain'),
    _CountryOption(iso: 'AT', dialCode: '43', flag: '🇦🇹', name: 'Austria'),
    _CountryOption(
      iso: 'CH',
      dialCode: '41',
      flag: '🇨🇭',
      name: 'Switzerland',
    ),
    _CountryOption(
      iso: 'UK',
      dialCode: '44',
      flag: '🇬🇧',
      name: 'United Kingdom',
    ),
    _CountryOption(
      iso: 'US',
      dialCode: '1',
      flag: '🇺🇸',
      name: 'United States',
    ),
    _CountryOption(iso: 'CA', dialCode: '1', flag: '🇨🇦', name: 'Canada'),
    _CountryOption(iso: 'AU', dialCode: '61', flag: '🇦🇺', name: 'Australia'),
    _CountryOption(iso: 'AE', dialCode: '971', flag: '🇦🇪', name: 'UAE'),
    _CountryOption(
      iso: 'SA',
      dialCode: '966',
      flag: '🇸🇦',
      name: 'Saudi Arabia',
    ),
    _CountryOption(
      iso: 'CI',
      dialCode: '225',
      flag: '🇨🇮',
      name: 'Ivory Coast',
    ),
    _CountryOption(iso: 'IN', dialCode: '91', flag: '🇮🇳', name: 'India'),
  ];

  String _t(String key) =>
      AppStrings.get(key, context.read<ThemeProvider>().language);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
    Color get _panelColor => Theme.of(context).cardColor;
    Color get _panelBorderColor => Theme.of(context).dividerColor;
    Color get _fieldFillColor =>
      Theme.of(context).inputDecorationTheme.fillColor ??
      (_isDark ? const Color(0xFF1B1B22) : const Color(0xFFF6F7FB));

  @override
  void initState() {
    super.initState();
    _seedFuture = _loadSeedData();
    _primeControllers();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _socialController.dispose();
    _toolController.dispose();
    super.dispose();
  }

  Future<_HomeSeedData> _loadSeedData() async {
    final phone = await _storageService.getUserPhone();
    final email = await _storageService.getUserEmail();
    final username = await _storageService.getUsername();
    final imagePath = await _storageService.getUserImagePath();
    final history = await _storageService.getSearchHistory();
    return _HomeSeedData(
      phone: phone,
      email: email,
      username: username,
      imagePath: imagePath,
      history: history,
    );
  }

  Future<void> _primeControllers() async {
    final seed = await _seedFuture;
    if (!mounted) {
      return;
    }

    final recentPhone = _projectHistory(seed.history).cleanedItems;

    setState(() {
      _chatController.text = seed.phone?.trim().isNotEmpty == true
          ? seed.phone!.trim()
          : (recentPhone.isNotEmpty ? recentPhone.first : '05521270516');

      _socialController.text = seed.email?.trim().isNotEmpty == true
          ? seed.email!.split('@').first
          : 'mehmetgokdeniz';

      _toolController.text = seed.email?.trim().isNotEmpty == true
          ? seed.email!.trim()
          : 'mehmet@example.com';
    });
  }

  Future<void> _pasteClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_t('pasteEmpty'));
      return;
    }

    setState(() {
      controller.text = text;
      controller.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  void _copyToClipboard(String text, {String successMessage = ''}) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(
      successMessage.isEmpty ? _t('clipboardCopied') : successMessage,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanHistoryItem(String item) {
    return item.replaceAll(_historyPrefixPattern, '').trim();
  }

  _HistoryProjection _projectHistory(List<String> history, {int? take}) {
    final originalByCleaned = <String, String>{};
    final cleanedItems = <String>[];

    for (final original in history) {
      final cleaned = _cleanHistoryItem(original);
      if (cleaned.isEmpty || originalByCleaned.containsKey(cleaned)) {
        continue;
      }

      originalByCleaned[cleaned] = original;
      cleanedItems.add(cleaned);

      if (take != null && cleanedItems.length >= take) {
        break;
      }
    }

    return _HistoryProjection(
      cleanedItems: cleanedItems,
      originalByCleaned: originalByCleaned,
    );
  }

  void _showSearchHistory(List<String> history) {
    final projected = _projectHistory(history);
    final historyMap = projected.originalByCleaned;
    final cleanedHistory = projected.cleanedItems;

    if (cleanedHistory.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? const Color(0xFF15151B) : Colors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Arama Geçmişi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await _storageService.clearSearchHistory();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      _showSnackBar('Geçmiş temizlendi');
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Temizle'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: cleanedHistory.length,
                  separatorBuilder: (_, __) => Divider(
                    color: _isDark ? Colors.white10 : const Color(0x1A000000),
                  ),
                  itemBuilder: (context, index) {
                    final item = cleanedHistory[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_rounded, size: 22),
                      title: Text(
                        item,
                        style: TextStyle(
                          color: _isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () async {
                          final originalItem = historyMap[item];
                          if (originalItem == null) {
                            return;
                          }
                          await _storageService.removeSearchItem(originalItem);
                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {
                              _seedFuture = _loadSeedData();
                            });
                            _showSnackBar('Silindi');
                          }
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _chatController.text = item;
                          _selectedTab = 0;
                          _selectedChatIndex = 0;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    _showSnackBar('Bağlantı açılamadı.');
  }

  String _cleanHandle(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._@+-]'), '').trim();
  }

  String _normalizePhone(String value) {
    var phone = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return phone;
  }

  TextInputType _keyboardTypeForChatAction(String action) {
    switch (action) {
      case 'whatsapp':
      case 'sms':
      case 'signal':
      case 'viber':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  String _chatHintForAction(String action) {
    switch (action) {
      case 'whatsapp':
        return _t('enterWhatsAppNumber');
      case 'sms':
        return _t('enterSmsNumber');
      case 'telegram':
        return _t('enterTelegramUsername');
      case 'signal':
        return _t('enterSignalNumber');
      case 'viber':
        return _t('enterViberNumber');
      case 'wechat':
        return _t('enterWeChatId');
      case 'line':
        return _t('enterLineId');
      case 'messenger':
        return _t('enterMessengerUsername');
      default:
        return _t('enterPhoneNumberShort');
    }
  }

  bool _requiresCountryPicker(String action) {
    return action == 'whatsapp' || action == 'sms';
  }

  _CountryOption get _selectedCountry {
    return _countryOptions.firstWhere(
      (country) => country.iso == _selectedCountryIso,
      orElse: () => _countryOptions.first,
    );
  }

  String _buildPhoneWithCountry(String rawPhone) {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    final local = cleaned.startsWith('0') ? cleaned.substring(1) : cleaned;
    return '+${_selectedCountry.dialCode}$local';
  }

  String _socialHintForAction(String action) {
    switch (action) {
      case 'discord':
        return _t('enterDiscordUsernameOrInvite');
      case 'instagram':
        return _t('enterInstagramUsername');
      case 'x':
        return _t('enterXUsername');
      case 'snapchat':
        return _t('enterSnapchatUsername');
      case 'youtube':
        return _t('enterYouTubeChannel');
      case 'tiktok':
        return _t('enterTikTokUsername');
      case 'twitch':
        return _t('enterTwitchUsername');
      case 'facebook':
        return _t('enterFacebookUsernameOrId');
      case 'kick':
        return _t('enterKickUsername');
      case 'linkedin':
        return _t('enterLinkedInUsername');
      default:
        return _t('enterUsernameOrId');
    }
  }

  String _getExamplePhoneForCountry(String countryIso) {
    final countryExamples = {
      'TR': '+90 551 943 7091',
      'DE': '+49 30 123456',
      'SE': '+46 8 1234567',
      'NO': '+47 2334 5678',
      'DK': '+45 3312 3456',
      'FI': '+358 9 123456',
      'NL': '+31 20 1234567',
      'BE': '+32 2 123 45 67',
      'FR': '+33 1 23 45 67 89',
      'IT': '+39 06 1234 5678',
      'ES': '+34 91 1234567',
      'AT': '+43 1 1234567',
      'CH': '+41 44 123 4567',
      'UK': '+44 20 1234 5678',
      'US': '+1 (555) 123-4567',
      'CA': '+1 (416) 123-4567',
      'AU': '+61 2 1234 5678',
      'AE': '+971 4 123 4567',
      'SA': '+966 11 1234567',
      'CI': '+225 07 12 34 56 78',
      'IN': '+91 11 1234 5678',
    };
    return countryExamples[countryIso] ?? '+90 551 943 7091';
  }

  String _watermarkTextForAction(String action, String title) {
    if (_requiresCountryPicker(action)) {
      final examplePhone = _getExamplePhoneForCountry(_selectedCountry.iso);
      return '$title • ${_selectedCountry.flag} $examplePhone';
    }

    switch (action) {
      case 'telegram':
        return '$title • -@mehmetgokdeniz';
      case 'signal':
        return '$title • -@mehmetgokdeniz';
      case 'viber':
        return '$title • -@mehmetgokdeniz';
      case 'wechat':
        return '$title • -@mehmetgokdeniz';
      case 'line':
        return '$title • -@mehmetgokdeniz';
      case 'messenger':
        return '$title • -@mehmetgokdeniz';
      case 'discord':
        return '$title • -@mehmetgokdeniz';
      case 'instagram':
        return '$title • -@mehmetgokdeniz';
      case 'x':
        return '$title • -@mehmetgokdeniz';
      case 'snapchat':
        return '$title • -@mehmetgokdeniz';
      case 'youtube':
        return '$title • -@mehmetgokdenizChannel';
      case 'tiktok':
        return '$title • -@mehmetgokdeniz';
      case 'twitch':
        return '$title • -@mehmetgokdeniz';
      case 'facebook':
        return '$title • -mehmet.gokdeniz';
      case 'kick':
        return '$title • -@mehmetgokdeniz';
      case 'linkedin':
        return '$title • -/in/mehmet-gokdeniz';
      case 'email':
        return '$title • -mehmet@example.com';
      default:
        return '$title • ${_t('enterUsernameOrId')}';
    }
  }

  Future<void> _handleChatAction(String action) async {
    final provider = context.read<QRScannerProvider>();
    final value = _chatController.text.trim();
    if (value.isEmpty) {
      _showSnackBar(_chatHintForAction(action));
      return;
    }

    try {
      switch (action) {
        case 'whatsapp':
          await provider.openWhatsApp(value, countryCode: _selectedCountryIso);
          await _storageService.addSearchHistory('WA: $value');
          break;
        case 'sms':
          await provider.openSMS(_buildPhoneWithCountry(value));
          await _storageService.addSearchHistory('SMS: $value');
          break;
        case 'telegram':
          await provider.openTelegram(value);
          await _storageService.addSearchHistory('TG: $value');
          break;
        case 'signal':
          await _openExternalUrl(
            'https://signal.me/#p/${_normalizePhone(value)}',
          );
          await _storageService.addSearchHistory('Signal: $value');
          break;
        case 'viber':
          await _openExternalUrl(
            'viber://chat?number=${_normalizePhone(value)}',
          );
          await _storageService.addSearchHistory('Viber: $value');
          break;
        case 'wechat':
          await _openExternalUrl('https://www.wechat.com/');
          break;
        case 'line':
          await _openExternalUrl(
            'https://line.me/R/ti/p/~${_cleanHandle(value)}',
          );
          await _storageService.addSearchHistory('LINE: $value');
          break;
        case 'messenger':
          await _openExternalUrl('https://m.me/${_cleanHandle(value)}');
          await _storageService.addSearchHistory('Messenger: $value');
          break;
      }
    } catch (e) {
      _showSnackBar('${_t('actionFailed')}$e');
    }
  }

  Future<void> _handleSocialAction(String action) async {
    final provider = context.read<QRScannerProvider>();
    final value = _socialController.text.trim();
    if (value.isEmpty) {
      _showSnackBar(_t('pleaseEnterUsernameOrId'));
      return;
    }

    try {
      switch (action) {
        case 'discord':
          await provider.openDiscord(value);
          await _storageService.addSearchHistory('Discord: $value');
          break;
        case 'instagram':
          await provider.openInstagram(value);
          await _storageService.addSearchHistory('Instagram: $value');
          break;
        case 'x':
          await provider.openX(value);
          await _storageService.addSearchHistory('X: $value');
          break;
        case 'snapchat':
          await _openExternalUrl(
            'https://www.snapchat.com/add/${_cleanHandle(value)}',
          );
          await _storageService.addSearchHistory('Snapchat: $value');
          break;
        case 'youtube':
          await provider.openYouTube(value);
          await _storageService.addSearchHistory('YouTube: $value');
          break;
        case 'tiktok':
          await _openExternalUrl(
            'https://www.tiktok.com/@${_cleanHandle(value)}',
          );
          await _storageService.addSearchHistory('TikTok: $value');
          break;
        case 'twitch':
          await _openExternalUrl(
            'https://www.twitch.tv/${_cleanHandle(value)}',
          );
          await _storageService.addSearchHistory('Twitch: $value');
          break;
        case 'facebook':
          await provider.openFacebook(value);
          await _storageService.addSearchHistory('Facebook: $value');
          break;
        case 'kick':
          await _openExternalUrl('https://kick.com/${_cleanHandle(value)}');
          await _storageService.addSearchHistory('Kick: $value');
          break;
        case 'linkedin':
          await provider.openLinkedIn(value);
          await _storageService.addSearchHistory('LinkedIn: $value');
          break;
      }
    } catch (e) {
      _showSnackBar('${_t('actionFailed')}$e');
    }
  }

  Future<void> _handleToolAction(String action) async {
    final value = _toolController.text.trim();

    switch (action) {
      case 'qr':
        Navigator.pushNamed(
          context,
          '/qr',
          arguments: value.isEmpty ? null : value,
        );
        break;
      case 'clean':
        _showLinkCleanerSheet();
        break;
      case 'encrypt':
        _showMessageEncryptorSheet();
        break;
    }
  }

  void _showLinkCleanerSheet() {
    final controller = TextEditingController(text: _toolController.text.trim());
    String cleaned = _cleanLink(controller.text);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t('linkCleaner'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('linkCleanerDesc'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: _inputDecoration(
                      controller: controller,
                      hintText: _t('linkCleanerHint'),
                      prefixIcon: Icons.link_off_rounded,
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        cleaned = _cleanLink(value);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _SheetResultCard(
                    title: _t('cleanLink'),
                    value: cleaned,
                    onCopy: cleaned.isEmpty
                        ? null
                        : () => _copyToClipboard(
                            cleaned,
                            successMessage: _t('cleanLinkCopied'),
                          ),
                    onOpen: cleaned.isNotEmpty
                        ? () => _openExternalUrl(cleaned)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: cleaned.isEmpty
                        ? null
                        : () {
                            _copyToClipboard(
                              cleaned,
                              successMessage: _t('cleanLinkCopied'),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(_t('copy')),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showMessageEncryptorSheet() {
    final controller = TextEditingController();
    String result = '';
    bool decodeMode = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              void refreshValue() {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  result = '';
                  return;
                }

                if (decodeMode) {
                  try {
                    result = utf8.decode(base64Decode(value));
                  } catch (_) {
                    result = _t('invalidBase64');
                  }
                } else {
                  result = base64Encode(utf8.encode(value));
                }
              }

              refreshValue();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t('messageEncryptor'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('messageEncryptorDesc'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ToggleButtons(
                    isSelected: [!decodeMode, decodeMode],
                    onPressed: (index) {
                      setSheetState(() {
                        decodeMode = index == 1;
                        refreshValue();
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF7C6BFF),
                    color: Colors.white70,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(_t('encrypt')),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(_t('decode')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      controller: controller,
                      hintText: decodeMode
                          ? 'UGVybmFtZQ=='
                          : _t('resultPlaceholder'),
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    onChanged: (_) {
                      setSheetState(refreshValue);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SheetResultCard(
                    title: decodeMode ? _t('decodedText') : _t('encryptedText'),
                    value: result,
                    onCopy: result.isEmpty
                        ? null
                        : () => _copyToClipboard(
                            result,
                            successMessage: _t('clipboardCopied'),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  String _cleanLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) {
      final normalized =
          trimmed.startsWith('http://') || trimmed.startsWith('https://')
          ? trimmed
          : 'https://$trimmed';
      uri = Uri.tryParse(normalized);
    }

    if (uri == null) {
      return trimmed;
    }

    final removedKeys = <String>{
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'utm_term',
      'utm_content',
      'gclid',
      'fbclid',
    };
    final filtered = <String, String>{};

    for (final entry in uri.queryParametersAll.entries) {
      if (removedKeys.contains(entry.key)) {
        continue;
      }
      if (entry.value.isNotEmpty) {
        filtered[entry.key] = entry.value.first;
      }
    }

    return uri.replace(queryParameters: filtered).toString();
  }

  InputDecoration _inputDecoration({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    final isDark = _isDark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      suffixIcon: IconButton(
        onPressed: () => _pasteClipboard(controller),
        icon: Icon(
          Icons.content_paste_rounded,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      filled: true,
      fillColor: _fieldFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _panelBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _panelBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeSeedData>(
      future: _seedFuture,
      builder: (context, snapshot) {
        final seed = snapshot.data ?? const _HomeSeedData(history: []);

        return Scaffold(
          body: Stack(
            children: [
              _BackgroundPattern(isDark: _isDark),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildProfileCard(seed),
                      const SizedBox(height: 18),
                      if (_selectedTab == 0) ...[
                        _buildRecentContacts(seed),
                        const SizedBox(height: 18),
                      ],
                      _buildTabSelector(),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _buildSelectedTabContent(seed),
                      ),
                      const SizedBox(height: 20),
                      _buildTrustCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final titleGradient = const LinearGradient(
      colors: [Color(0xFF7A7CFF), Color(0xFF9B59FF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF5FB6FF), Color(0xFF9A63FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A7DFF).withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Transform.scale(
            scale: 1.15,
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => titleGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              _t('appName'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/history'),
          icon: Icon(
            Icons.history_rounded,
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: Icon(
            Icons.settings_rounded,
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(_HomeSeedData seed) {
    final hasProfileImage = (seed.imagePath ?? '').isNotEmpty;
    final hasUsername = (seed.username ?? '').isNotEmpty;

    if (!hasProfileImage && !hasUsername) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _panelBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isDark
                  ? const Color(0xFF2F2F3D)
                  : const Color(0xFFE8ECFA),
              border: Border.all(
                color: _isDark
                    ? const Color(0xFF3F3F4D)
                    : const Color(0xFFC8D0E0),
                width: 1.5,
              ),
            ),
            child: hasProfileImage
                ? ClipOval(
                    child: Image.file(
                      File(seed.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle,
                        color: _isDark ? Colors.white54 : Colors.black38,
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    Icons.account_circle,
                    color: _isDark ? Colors.white54 : Colors.black38,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('myProfile'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasUsername ? seed.username! : _t('unknown'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              color: _isDark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            onPressed: () => Navigator.pushNamed(context, '/profile').then((_) {
              setState(() {
                _seedFuture = _loadSeedData();
              });
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentContacts(_HomeSeedData seed) {
    final projected = _projectHistory(seed.history, take: 5);
    final historyMap = projected.originalByCleaned;
    final items = projected.cleanedItems;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Aramalar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (seed.history.isNotEmpty)
              GestureDetector(
                onTap: () => _showSearchHistory(seed.history),
                child: Text(
                  'Geçmişi Gör',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D7BFF),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isDarkTheme = _isDark;
              final chipColor = isDarkTheme
                  ? const Color(0xFF6D7BFF)
                  : const Color(0xFF5568FF);

              return InputChip(
                backgroundColor: chipColor,
                avatar: const Icon(
                  Icons.chat_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  items[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _chatController.text = items[index];
                    _selectedTab = 0;
                    _selectedChatIndex = 0;
                  });
                },
                onDeleted: () async {
                  final originalItem = historyMap[items[index]];
                  if (originalItem == null) {
                    return;
                  }
                  await _storageService.removeSearchItem(originalItem);
                  setState(() {
                    _seedFuture = _loadSeedData();
                  });
                  _showSnackBar('Kişi silindi');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      (_t('chat'), Icons.chat_bubble_outline_rounded),
      (_t('socialMedia'), Icons.groups_rounded),
      (_t('tools'), Icons.handyman_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorderColor),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF7F77FF), Color(0xFFB46CFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[index].$2,
                        color: selected
                            ? Colors.white
                            : (_isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tabs[index].$1,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : (_isDark ? Colors.white70 : Colors.black54),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTabContent(_HomeSeedData seed) {
    switch (_selectedTab) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('chat'),
          child: _buildChatSection(),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('social'),
          child: _buildSocialSection(seed),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('tools'),
          child: _buildToolsSection(seed),
        );
    }
  }

  Widget _buildChatSection() {
    final items = [
      _ShortcutItem(
        title: 'WhatsApp',
        color: const Color(0xFF22C55E),
        icon: FontAwesomeIcons.whatsapp,
        actionKey: 'whatsapp',
        active: _selectedChatIndex == 0,
      ),
      _ShortcutItem(
        title: 'SMS',
        color: const Color(0xFFF59E0B),
        icon: Icons.sms_rounded,
        actionKey: 'sms',
        active: _selectedChatIndex == 1,
      ),
      _ShortcutItem(
        title: 'Telegram',
        color: const Color(0xFF229ED9),
        icon: FontAwesomeIcons.telegram,
        actionKey: 'telegram',
        active: _selectedChatIndex == 2,
      ),
      _ShortcutItem(
        title: 'Signal',
        color: const Color(0xFF3B82F6),
        icon: FontAwesomeIcons.signalMessenger,
        actionKey: 'signal',
        active: _selectedChatIndex == 3,
      ),
      _ShortcutItem(
        title: 'Viber',
        color: const Color(0xFF7C3AED),
        icon: FontAwesomeIcons.viber,
        actionKey: 'viber',
        active: _selectedChatIndex == 4,
      ),
      _ShortcutItem(
        title: 'WeChat',
        color: const Color(0xFF10B981),
        icon: FontAwesomeIcons.weixin,
        actionKey: 'wechat',
        active: _selectedChatIndex == 5,
      ),
      _ShortcutItem(
        title: 'LINE',
        color: const Color(0xFF22C55E),
        icon: FontAwesomeIcons.line,
        actionKey: 'line',
        active: _selectedChatIndex == 6,
      ),
      _ShortcutItem(
        title: 'Messenger',
        color: const Color(0xFF00B2FF),
        icon: FontAwesomeIcons.facebookMessenger,
        actionKey: 'messenger',
        active: _selectedChatIndex == 7,
      ),
    ];

    return Column(
      children: [
        _buildGridCard(
          items,
          crossAxisCount: 4,
          onTap: (item, index) {
            setState(() {
              _selectedChatIndex = index;
            });
          },
        ),
        if (_requiresCountryPicker(items[_selectedChatIndex].actionKey)) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _panelBorderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountryIso,
                isExpanded: true,
                dropdownColor: _isDark
                    ? const Color(0xFF1F1F28)
                    : const Color(0xFFFFFFFF),
                style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                iconEnabledColor: _isDark ? Colors.white70 : Colors.black54,
                items: _countryOptions.map((country) {
                  return DropdownMenuItem<String>(
                    value: country.iso,
                    child: Text(
                      '${country.flag} +${country.dialCode} ${country.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCountryIso = value;
                  });
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _buildActionComposer(
          controller: _chatController,
          icon: items[_selectedChatIndex].icon,
          iconColor: items[_selectedChatIndex].color,
          buttonGradient: const [Color(0xFF5A66FF), Color(0xFF6D9CFF)],
          buttonText: '${_t('open')} ${items[_selectedChatIndex].title}',
          onPressed: () =>
              _handleChatAction(items[_selectedChatIndex].actionKey),
          hintText: _chatHintForAction(items[_selectedChatIndex].actionKey),
          watermarkText: _watermarkTextForAction(
            items[_selectedChatIndex].actionKey,
            items[_selectedChatIndex].title,
          ),
          keyboardType: _keyboardTypeForChatAction(
            items[_selectedChatIndex].actionKey,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(_HomeSeedData seed) {
    final projected = _projectHistory(seed.history);
    final historyMap = projected.originalByCleaned;
    final cleanedHistory = projected.cleanedItems;

    final items = [
      _ShortcutItem(
        title: 'Discord',
        color: const Color(0xFF5865F2),
        icon: FontAwesomeIcons.discord,
        actionKey: 'discord',
        active: _selectedSocialIndex == 0,
      ),
      _ShortcutItem(
        title: 'Instagram',
        color: const Color(0xFFEF476F),
        icon: FontAwesomeIcons.instagram,
        actionKey: 'instagram',
        active: _selectedSocialIndex == 1,
      ),
      _ShortcutItem(
        title: 'X (Twitter)',
        color: const Color(0xFF111111),
        icon: FontAwesomeIcons.xTwitter,
        actionKey: 'x',
        active: _selectedSocialIndex == 2,
      ),
      _ShortcutItem(
        title: 'Snapchat',
        color: const Color(0xFFFFE812),
        icon: FontAwesomeIcons.snapchat,
        actionKey: 'snapchat',
        active: _selectedSocialIndex == 3,
      ),
      _ShortcutItem(
        title: 'YouTube',
        color: const Color(0xFFFF0000),
        icon: FontAwesomeIcons.youtube,
        actionKey: 'youtube',
        active: _selectedSocialIndex == 4,
      ),
      _ShortcutItem(
        title: 'TikTok',
        color: const Color(0xFF000000),
        icon: FontAwesomeIcons.tiktok,
        actionKey: 'tiktok',
        active: _selectedSocialIndex == 5,
      ),
      _ShortcutItem(
        title: 'Twitch',
        color: const Color(0xFF9146FF),
        icon: FontAwesomeIcons.twitch,
        actionKey: 'twitch',
        active: _selectedSocialIndex == 6,
      ),
      _ShortcutItem(
        title: 'Facebook',
        color: const Color(0xFF1877F2),
        icon: FontAwesomeIcons.facebook,
        actionKey: 'facebook',
        active: _selectedSocialIndex == 7,
      ),
      _ShortcutItem(
        title: 'Kick',
        color: const Color(0xFF7CFF2F),
        icon: FontAwesomeIcons.kickstarterK,
        actionKey: 'kick',
        active: _selectedSocialIndex == 8,
      ),
      _ShortcutItem(
        title: 'LinkedIn',
        color: const Color(0xFF0A66C2),
        icon: FontAwesomeIcons.linkedin,
        actionKey: 'linkedin',
        active: _selectedSocialIndex == 9,
      ),
    ];

    return Column(
      children: [
        if (cleanedHistory.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Aramalar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showSearchHistory(seed.history),
                    child: Text(
                      'Geçmişi Gör',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6D7BFF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cleanedHistory.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isDarkTheme = _isDark;
                    final chipColor = isDarkTheme
                        ? const Color(0xFF6D7BFF)
                        : const Color(0xFF5568FF);

                    return InputChip(
                      backgroundColor: chipColor,
                      avatar: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        cleanedHistory[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      deleteIcon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _socialController.text = cleanedHistory[index];
                          _selectedSocialIndex = 1;
                        });
                      },
                      onDeleted: () async {
                        final originalItem = historyMap[cleanedHistory[index]];
                        if (originalItem != null) {
                          await _storageService.removeSearchItem(originalItem);
                          setState(() {
                            _seedFuture = _loadSeedData();
                          });
                          _showSnackBar('Silindi');
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ],
        _buildGridCard(
          items,
          crossAxisCount: 4,
          onTap: (item, index) {
            setState(() {
              _selectedSocialIndex = index;
            });
          },
        ),
        const SizedBox(height: 18),
        _buildActionComposer(
          controller: _socialController,
          icon: items[_selectedSocialIndex].icon,
          iconColor: items[_selectedSocialIndex].color,
          buttonGradient: const [Color(0xFF5A66FF), Color(0xFF8D6DFF)],
          buttonText: '${_t('open')} ${items[_selectedSocialIndex].title}',
          onPressed: () =>
              _handleSocialAction(items[_selectedSocialIndex].actionKey),
          hintText: _socialHintForAction(items[_selectedSocialIndex].actionKey),
          watermarkText: _watermarkTextForAction(
            items[_selectedSocialIndex].actionKey,
            items[_selectedSocialIndex].title,
          ),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildToolsSection(_HomeSeedData seed) {
    final items = [
      _ShortcutItem(
        title: _t('qrGenerator'),
        color: const Color(0xFF7C6BFF),
        icon: Icons.qr_code_rounded,
        actionKey: 'qr',
        active: _selectedToolIndex == 0,
      ),
      _ShortcutItem(
        title: _t('linkToolsTitle'),
        color: const Color(0xFF00BCD4),
        icon: Icons.link_off_rounded,
        actionKey: 'clean',
        active: _selectedToolIndex == 1,
      ),
      _ShortcutItem(
        title: _t('encryptToolsTitle'),
        color: const Color(0xFFFF6B9D),
        icon: Icons.lock_outline_rounded,
        actionKey: 'encrypt',
        active: _selectedToolIndex == 2,
      ),
    ];

    return Column(
      children: [
        _buildGridCard(
          items,
          crossAxisCount: 3,
          onTap: (item, index) {
            setState(() {
              _selectedToolIndex = index;
            });
            _handleToolAction(item.actionKey);
          },
          compact: true,
        ),
      ],
    );
  }

  Widget _buildGridCard(
    List<_ShortcutItem> items, {
    required int crossAxisCount,
    required void Function(_ShortcutItem item, int index) onTap,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF17171E) : const Color(0xFFF4F6FD),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isDark ? const Color(0xFF2F2F3D) : const Color(0xFFD6DBEA),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: compact ? 8 : 10,
          crossAxisSpacing: compact ? 8 : 10,
          childAspectRatio: compact ? 1.08 : 1.04,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ShortcutTile(
            item: item,
            compact: compact,
            isDark: _isDark,
            onTap: () => onTap(item, index),
          );
        },
      ),
    );
  }

  Widget _buildActionComposer({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required List<Color> buttonGradient,
    required String buttonText,
    required VoidCallback onPressed,
    required String hintText,
    String? watermarkText,
    required TextInputType keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF17171E) : const Color(0xFFF4F6FD),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isDark ? const Color(0xFF2F2F3D) : const Color(0xFFD6DBEA),
        ),
      ),
      child: Column(
        children: [
          if (watermarkText != null && watermarkText.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDark
                      ? [const Color(0xFF2A3A5C), const Color(0xFF1F2A4A)]
                      : [const Color(0xFFE3EAFF), const Color(0xFFD6E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDark
                      ? const Color(0xFF6D7BFF).withValues(alpha: 0.4)
                      : const Color(0xFF6D7BFF).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D7BFF).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D7BFF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: Color(0xFF6D7BFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      watermarkText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isDark ? Colors.white : const Color(0xFF1A1F3A),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF21212A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: _isDark ? Colors.white54 : Colors.black45,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: keyboardType,
                  ),
                ),
                IconButton(
                  onPressed: () => _pasteClipboard(controller),
                  icon: Icon(
                    Icons.content_paste_rounded,
                    color: _isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: buttonGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, color: Colors.white),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFB7A8FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t('trustCardMessage'),
              style: TextStyle(
                fontSize: 15,
                color: _isDark ? Colors.white70 : Colors.black54,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPattern extends StatelessWidget {
  const _BackgroundPattern({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradientColors = isDark
        ? const [Color(0xFF0C0D14), Color(0xFF101420), Color(0xFF0C0D14)]
        : [
            Theme.of(context).scaffoldBackgroundColor,
            scheme.surface,
            scheme.surface.withValues(alpha: 0.92),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(
          color: scheme.outline.withValues(alpha: isDark ? 0.28 : 0.22),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    const step = 42.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.item,
    required this.onTap,
    required this.compact,
    required this.isDark,
  });

  final _ShortcutItem item;
  final VoidCallback onTap;
  final bool compact;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: item.active
                ? item.color.withValues(alpha: 0.65)
                : (isDark ? const Color(0xFF343444) : const Color(0xFFD8DDEA)),
            width: item.active ? 1.4 : 1,
          ),
          color: item.active
              ? item.color.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF1C1C24) : Colors.white),
          boxShadow: [
            if (item.active)
              BoxShadow(
                color: item.color.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 8 : 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 38 : 40,
              height: compact ? 38 : 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    item.color.withValues(alpha: 0.85),
                    item.color.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: compact ? 18 : 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: item.active
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 26),
    );
  }
}

class _SheetResultCard extends StatelessWidget {
  const _SheetResultCard({
    required this.title,
    required this.value,
    this.onCopy,
    this.onOpen,
  });

  final String title;
  final String value;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<ThemeProvider>().language;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF353545)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            value.isEmpty
                ? AppStrings.get('resultPlaceholder', language)
                : value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onCopy != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCopy,
                    child: Text(AppStrings.get('copy', language)),
                  ),
                ),
              if (onCopy != null && onOpen != null) const SizedBox(width: 10),
              if (onOpen != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpen,
                    child: Text(AppStrings.get('openLink', language)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  _ShortcutItem({
    required this.title,
    required this.color,
    required this.icon,
    required this.actionKey,
    required this.active,
  });

  final String title;
  final Color color;
  final IconData icon;
  final String actionKey;
  final bool active;
}

class _HomeSeedData {
  const _HomeSeedData({
    this.phone,
    this.email,
    this.username,
    this.imagePath,
    required this.history,
  });

  final String? phone;
  final String? email;
  final String? username;
  final String? imagePath;
  final List<String> history;
}

class _HistoryProjection {
  const _HistoryProjection({
    required this.cleanedItems,
    required this.originalByCleaned,
  });

  final List<String> cleanedItems;
  final Map<String, String> originalByCleaned;
}

class _CountryOption {
  const _CountryOption({
    required this.iso,
    required this.dialCode,
    required this.flag,
    required this.name,
  });

  final String iso;
  final String dialCode;
  final String flag;
  final String name;
}
