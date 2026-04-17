import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_strings.dart';
import '../../data/services/app_storage_service.dart';
import '../../presentation/providers/theme_provider.dart';
import 'profile_creation_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storageService = AppStorageService();
  final _imagePicker = ImagePicker();
  late Future<Map<String, String?>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _loadProfileData();
  }

  Future<Map<String, String?>> _loadProfileData() async {
    final username = await _storageService.getUsername();
    final imagePath = await _storageService.getUserImagePath();
    return {'username': username, 'imagePath': imagePath};
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web üzerinde resim seçme desteklenmiyor.'),
          ),
        );
      }
      return;
    }
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await _storageService.updateUserImage(file.path);
        setState(() {
          _loadProfile();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Resim seçilirken hata: $e')));
      }
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) return;
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await _storageService.updateUserImage(file.path);
        setState(() {
          _loadProfile();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf çekilirken hata: $e')));
      }
    }
  }

  Future<void> _resetProfile() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Profili Sıfırla'),
        content: const Text(
          'Profil bilgileriniz silinecektir. Devam etmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await _storageService.resetProfile();
              if (mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/profile');
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final language = themeProvider.language;

        return PopScope(
          canPop: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppStrings.get('settings', language)),
              centerTitle: true,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // Profil Bölümü
                    Center(
                      child: FutureBuilder<Map<String, String?>>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            );
                          }

                          final username = snapshot.data!['username'];
                          final imagePath = snapshot.data!['imagePath'];

                          return Column(
                            children: [
                              const SizedBox(height: 40),
                              // Profil Resmi
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (_) => Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.camera),
                                              title: const Text(
                                                'Kamera ile Çek',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _takePhoto();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.image),
                                              title: const Text(
                                                'Galeriden Seç',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (_) => Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.camera),
                                              title: const Text(
                                                'Kamera ile Çek',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _takePhoto();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.image),
                                              title: const Text(
                                                'Galeriden Seç',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade600,
                                          Colors.purple.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child:
                                        imagePath != null &&
                                            imagePath.isNotEmpty &&
                                            !kIsWeb
                                        ? ClipOval(
                                            child: Image.file(
                                              File(imagePath),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt,
                                                size: 48,
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Resim Değiştir',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Kullanıcı Adı
                              Text(
                                username ?? AppStrings.get('user', language),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Düzenle Butonu
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProfileCreationScreen(
                                                  isEditMode: true,
                                                ),
                                          ),
                                        );
                                    if (result == true) {
                                      setState(() {
                                        _loadProfile();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: Text(AppStrings.get('edit', language)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    backgroundColor: Colors.blue.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                      ),
                    ),

                    // Tema Ayarı
                    ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      title: Text(AppStrings.get('theme', language)),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? AppStrings.get('darkMode', language)
                            : AppStrings.get('lightMode', language),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.setTheme(value ? 'dark' : 'light');
                        },
                      ),
                    ),

                    // Dil Seçimi
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(AppStrings.get('language', language)),
                      subtitle: Text(
                        language == 'tr'
                            ? 'Türkçe'
                            : language == 'en'
                            ? 'English'
                            : language == 'ar'
                            ? 'العربية'
                            : language == 'fr'
                            ? 'Français'
                            : language == 'ja'
                            ? '日本語'
                            : language == 'ku'
                            ? 'Kurdî'
                            : language == 'hi'
                            ? 'हिन्दी'
                            : language == 'ru'
                            ? 'Русский'
                            : language == 'de'
                            ? 'Deutsch'
                            : language == 'pt'
                            ? 'Português'
                            : language == 'ko'
                            ? '한국어'
                            : language == 'zh'
                            ? '中文'
                            : language == 'it'
                            ? 'Italiano'
                            : language == 'es'
                            ? 'Español'
                            : language,
                      ),
                      trailing: DropdownButton<String>(
                        value: language,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: 'tr',
                            child: const Text('Türkçe'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: const Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: const Text('العربية'),
                          ),
                          DropdownMenuItem(
                            value: 'fr',
                            child: const Text('Français'),
                          ),
                          DropdownMenuItem(
                            value: 'ja',
                            child: const Text('日本語'),
                          ),
                          DropdownMenuItem(
                            value: 'ku',
                            child: const Text('Kurdî'),
                          ),
                          DropdownMenuItem(
                            value: 'hi',
                            child: const Text('हिन्दी'),
                          ),
                          DropdownMenuItem(
                            value: 'ru',
                            child: const Text('Русский'),
                          ),
                          DropdownMenuItem(
                            value: 'de',
                            child: const Text('Deutsch'),
                          ),
                          DropdownMenuItem(
                            value: 'pt',
                            child: const Text('Português'),
                          ),
                          DropdownMenuItem(
                            value: 'ko',
                            child: const Text('한국어'),
                          ),
                          DropdownMenuItem(
                            value: 'zh',
                            child: const Text('中文'),
                          ),
                          DropdownMenuItem(
                            value: 'it',
                            child: const Text('Italiano'),
                          ),
                          DropdownMenuItem(
                            value: 'es',
                            child: const Text('Español'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            themeProvider.setLanguage(value);
                          }
                        },
                      ),
                    ),

                    const Divider(),

                    // Hakkında Bölümü
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: Text(AppStrings.get('about', language)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(AppStrings.get('aboutTitle', language)),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'FastGokdeniz',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(AppStrings.get('aboutDesc', language)),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppStrings.get('features', language),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.get('feature1', language),
                                        ),
                                        Text(
                                          AppStrings.get('feature2', language),
                                        ),
                                        Text(
                                          AppStrings.get('feature3', language),
                                        ),
                                        Text(
                                          AppStrings.get('feature4', language),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppStrings.get('close', language)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Telif Hakları / Geliştiren Bilgisi
                    ListTile(
                      leading: const Icon(Icons.copyright),
                      title: Text(AppStrings.get('copyrights', language)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(
                              AppStrings.get('copyrightTitle', language),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'FastGokdeniz',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.get(
                                      'allRightsReserved',
                                      language,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    language == 'tr'
                                        ? 'Bu uygulama Mehmet Gökdeniz tarafından geliştirilmiş ve yönetilmektedir.'
                                        : 'This application has been developed and is managed by Mehmet Gökdeniz.',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    language == 'tr'
                                        ? 'Uygulamadaki tüm ticari markalar, logolar ve ürün isimleri ilgili şirketlerine aittir.'
                                        : 'All trademarks, logos and product names in the application belong to their respective companies.',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppStrings.get('openSource', language),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Flutter Framework\n'
                                    '• Provider\n'
                                    '• Shared Preferences\n'
                                    '• URL Launcher\n'
                                    '• QR Flutter\n'
                                    '• Mobile Scanner\n'
                                    '• Get IT\n'
                                    '• Flutter SVG',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppStrings.get('close', language)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // Profili Sıfırla
                    ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.red),
                      title: Text(
                        AppStrings.get('resetProfile', language),
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: _resetProfile,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
