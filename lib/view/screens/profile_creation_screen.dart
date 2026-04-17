import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../data/services/app_storage_service.dart';

class ProfileCreationScreen extends StatefulWidget {
  final bool isEditMode;

  const ProfileCreationScreen({super.key, this.isEditMode = false});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _usernameController = TextEditingController();
  final _storageService = AppStorageService();
  File? _selectedImage;
  String? _existingImagePath;
  bool _isLoading = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    try {
      final username = (await _storageService.getUsername()) ?? '';
      final imagePath = (await _storageService.getUserImagePath()) ?? '';

      setState(() {
        _usernameController.text = username;
        _existingImagePath = imagePath.isNotEmpty ? imagePath : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web platformunda resim seçimi desteklenmiyor'),
            backgroundColor: Colors.orange,
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
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web platformunda kamera desteklenmiyor'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf çekilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _createProfile() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kullanıcı adı girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _storageService.createProfile(
        username: _usernameController.text,
        imagePath: _selectedImage?.path ?? _existingImagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Profil başarıyla güncellendi!'
                  : 'Profil başarıyla oluşturuldu!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isEditMode) {
          Navigator.of(context).pop(true); // Return true to indicate refresh
        } else {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditMode ? 'Profil Düzenle' : 'Profil Oluştur'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Profil Resmi
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.image),
                                title: const Text('Galeriden Seç'),
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
                      width: 150,
                      height: 150,
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
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _selectedImage != null && !kIsWeb
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _existingImagePath != null && !kIsWeb
                          ? ClipOval(
                              child: Image.file(
                                File(_existingImagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Resim Ekle',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Kullanıcı Adı
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kullanıcı Adı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı adınızı girin',
                      prefixIcon: const Icon(Icons.person),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Profil Oluştur/Düzenle Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.isEditMode
                                  ? 'Profili Kaydet'
                                  : 'Profil Oluştur',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
