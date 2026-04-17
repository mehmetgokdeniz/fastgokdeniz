import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
  as mlkit;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../presentation/providers/qr_provider.dart';
import '../../presentation/providers/theme_provider.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  late TextEditingController _urlController;
  final GlobalKey _qrImageKey = GlobalKey();
  final mlkit.BarcodeScanner _galleryBarcodeScanner = mlkit.BarcodeScanner(
    formats: const [mlkit.BarcodeFormat.qrCode],
  );
  late final MobileScannerController _scannerController;

  int _selectedToolTab = 0;
  String _selectedQrStyle = 'classic';

  double _qrSize = 220;
  double _innerSpacing = 16;
  double _borderRadius = 14;
  double _borderThickness = 0;
  double _borderShadow = 0;
  double _exportQuality = 4.0;

  Color _foregroundColor = Colors.black;
  Color _backgroundColor = Colors.white;

  bool _eyeCircle = false;
  bool _dataCircle = false;
  bool _leaveModuleGap = true;

  String _centerImage = 'none';
  File? _customCenterImageFile;
  int _errorLevel = QrErrorCorrectLevel.H;
  String? _lastScannedValue;
  bool _isHandlingLiveScan = false;
  bool _scannerShouldBeActive = false;

  final List<String> _qrStyles = const [
    'classic',
    'modern',
    'night',
    'ocean',
    'neon',
    'custom',
  ];

  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Color(0xFF6D4CB3),
    Color(0xFF1F6BC1),
    Color(0xFF0F766E),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
  ];

  String get _language => context.read<ThemeProvider>().language;

  String _t(String key) => AppStrings.get(key, _language);

  String _styleLabel(String style) {
    switch (style) {
      case 'classic':
        return _t('qrStyleClassic');
      case 'modern':
        return _t('qrStyleModern');
      case 'night':
        return _t('qrStyleNight');
      case 'ocean':
        return _t('qrStyleOcean');
      case 'neon':
        return _t('qrStyleNeon');
      case 'custom':
        return _t('qrStyleCustom');
      default:
        return style;
    }
  }

  String _centerImageLabel(String option) {
    switch (option) {
      case 'none':
        return _t('qrCenterImageNone');
      case 'appLogo':
        return _t('qrCenterImageAppLogo');
      case 'custom':
        return _t('qrCenterImageCustom');
      default:
        return option;
    }
  }

  Future<void> _ensureCameraScannerRunning() async {
    try {
      await _scannerController.start();
    } catch (_) {
      // Scanner widget will surface camera failures visually.
    }
  }

  Future<void> _setToolTab(int index) async {
    _scannerShouldBeActive = index == 1;

    if (_selectedToolTab == index) {
      if (_scannerShouldBeActive) {
        await _ensureCameraScannerRunning();
      }
      return;
    }

    if (_selectedToolTab == 1 && !_scannerShouldBeActive) {
      try {
        await _scannerController.stop();
      } catch (_) {
        // Ignore stop failures during tab transition.
      }
    }

    if (!mounted) return;
    setState(() => _selectedToolTab = index);

    if (_scannerShouldBeActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scannerShouldBeActive) return;
        _ensureCameraScannerRunning();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: false,
    );
    _urlController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<QRProvider>(context, listen: false);
      final route = ModalRoute.of(context);
      await provider.loadCreatedQrHistory();

      if (!mounted) return;
      final url = route?.settings.arguments as String?;
      if (url != null && url.isNotEmpty) {
        _urlController.text = url;
        provider.setUrl(url);
        provider.generateQR();
      }
    });
  }

  @override
  void dispose() {
    _galleryBarcodeScanner.close();
    _scannerShouldBeActive = false;
    try {
      _scannerController.stop();
    } catch (_) {
      // Ignore if controller is already stopped/disposed.
    }
    _scannerController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary =
          _qrImageKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: _exportQuality);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveQrPng() async {
    final bytes = await _captureQrImage();
    if (!mounted) return;

    final language =
        Provider.of<ThemeProvider>(context, listen: false).language;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('qrImageError', language))),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('webShareNotSupported', language)),
        ),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      path.join(
        directory.path,
        'qr_${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    );
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppStrings.get('saveQR', language)}: ${file.path}')),
    );
  }

  Future<void> _shareQrPng() async {
    final bytes = await _captureQrImage();
    if (!mounted) return;

    final language =
        Provider.of<ThemeProvider>(context, listen: false).language;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('qrImageError', language))),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('webShareNotSupported', language)),
        ),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'qr_code.png'));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: AppStrings.get('qrShareText', language),
    );
  }

  void _applyTemplate(String key) {
    final provider = Provider.of<QRProvider>(context, listen: false);
    final value = switch (key) {
      'url' => 'https://example.com',
      'email' => 'mailto:mehmet@example.com?subject=Konu&body=Mesaj',
      'phone' => 'tel:+905551112233',
      'sms' => 'SMSTO:+905551112233:Merhaba',
      'wifi' => 'WIFI:T:WPA;S:WiFiAdi;P:Sifre12345;;',
      _ => '',
    };

    _urlController.text = value;
    provider.setUrl(value);
  }

  void _applyStylePreset(String style) {
    setState(() {
      _selectedQrStyle = style;

      switch (style) {
        case 'classic':
          _foregroundColor = Colors.black;
          _backgroundColor = Colors.white;
          _borderRadius = 14;
          break;
        case 'modern':
          _foregroundColor = const Color(0xFF6D4CB3);
          _backgroundColor = Colors.white;
          _borderRadius = 16;
          _dataCircle = true;
          break;
        case 'night':
          _foregroundColor = Colors.white;
          _backgroundColor = Colors.black;
          _borderRadius = 10;
          break;
        case 'ocean':
          _foregroundColor = const Color(0xFF0F766E);
          _backgroundColor = const Color(0xFFEAF8F7);
          _borderRadius = 14;
          break;
        case 'neon':
          _foregroundColor = const Color(0xFF16E0C8);
          _backgroundColor = const Color(0xFF121219);
          _borderRadius = 18;
          _eyeCircle = true;
          _dataCircle = true;
          break;
        case 'custom':
          break;
      }
    });
  }

  String _errorLevelText(int value) {
    if (value == QrErrorCorrectLevel.L) return 'L (%7)';
    if (value == QrErrorCorrectLevel.M) return 'M (%15)';
    if (value == QrErrorCorrectLevel.Q) return 'Q (%25)';
    return 'H (%30)';
  }

  String _hexColor(Color color) {
    final argb = color.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _showColorPicker(String type) {
    final start = type == 'foreground' ? _foregroundColor : _backgroundColor;
    final startArgb = start.toARGB32();

    double red = ((startArgb >> 16) & 0xFF).toDouble();
    double green = ((startArgb >> 8) & 0xFF).toDouble();
    double blue = (startArgb & 0xFF).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16171D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final selected = Color.fromARGB(
              255,
              red.round(),
              green.round(),
              blue.round(),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Text(
                    _t('qrSelectColorTitle'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _hexColor(selected),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: selected.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: red,
                    min: 0,
                    max: 255,
                    activeColor: Colors.redAccent,
                    onChanged: (v) => setSheetState(() => red = v),
                  ),
                  Slider(
                    value: green,
                    min: 0,
                    max: 255,
                    activeColor: Colors.lightGreen,
                    onChanged: (v) => setSheetState(() => green = v),
                  ),
                  Slider(
                    value: blue,
                    min: 0,
                    max: 255,
                    activeColor: Colors.lightBlueAccent,
                    onChanged: (v) => setSheetState(() => blue = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (type == 'foreground') {
                            _foregroundColor = selected;
                          } else {
                            _backgroundColor = selected;
                          }
                        });
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(_t('qrApplyColor')),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFF8D79D8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openIfUrl(String text) async {
    final raw = text.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('qrUrlInvalid'))),
      );
      return;
    }

    final encodedRaw = Uri.encodeFull(raw);
    Uri? uri = Uri.tryParse(encodedRaw);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('qrUrlInvalid'))),
      );
      return;
    }

    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$encodedRaw');
    }

    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('qrUrlInvalid'))),
      );
      return;
    }

    var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('qrUrlOpenFailed'))),
      );
    }
  }

  ImageProvider<Object>? _embeddedImageProvider(QRProvider provider) {
    if (_centerImage == 'none') {
      return null;
    }

    if (_centerImage == 'appLogo') {
      return const AssetImage('assets/icon/app_icon.png');
    }

    if (_centerImage == 'custom' && _customCenterImageFile != null) {
      return FileImage(_customCenterImageFile!);
    }

    return null;
  }

  Future<void> _pickCustomCenterImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      setState(() {
        _customCenterImageFile = File(pickedFile.path);
        _centerImage = 'custom';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('qrCustomImagePickFailed')}: $e')),
      );
    }
  }

  Future<void> _showScannedResult(String scannedText) async {
    if (!mounted) return;

    setState(() => _lastScannedValue = scannedText);

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('qrReadTitle'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2B35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  scannedText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: scannedText));
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_t('qrContentCopiedShort'))),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(_t('copy')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                        _urlController.text = scannedText;
                        Provider.of<QRProvider>(context, listen: false)
                            .setUrl(scannedText);
                          _setToolTab(0);
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.input_rounded),
                      label: Text(_t('qrUseContent')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openIfUrl(scannedText),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(_t('qrOpenAsUrl')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanPickedGalleryImage(XFile pickedFile) async {
    try {
      final inputImage = mlkit.InputImage.fromFilePath(pickedFile.path);
      final barcodes = await _galleryBarcodeScanner.processImage(inputImage);

      String? raw;
      for (final code in barcodes) {
        final value = code.rawValue?.trim();
        if (value != null && value.isNotEmpty) {
          raw = value;
          break;
        }
      }

      if (!mounted) return;

      if (raw == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('qrUnreadable'))),
        );
        return;
      }

      await _showScannedResult(raw);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('error')} $e')),
      );
    }
  }

  Future<void> _pickAndScanFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile == null) return;

      await _scanPickedGalleryImage(pickedFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('error')} $e')),
      );
    }
  }

  Future<void> _handleLiveDetection(BarcodeCapture capture) async {
    if (_isHandlingLiveScan) {
      return;
    }

    String? raw;
    for (final code in capture.barcodes) {
      final value = code.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        raw = value;
        break;
      }
    }

    if (raw == null) {
      return;
    }

    _isHandlingLiveScan = true;

    try {
      await _scannerController.stop();
      if (!mounted) return;
      await _showScannedResult(raw);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('error')} $e')),
        );
      }
    } finally {
      _isHandlingLiveScan = false;
      if (mounted && _scannerShouldBeActive) {
        try {
          await _scannerController.start();
        } catch (_) {
          // If restart fails, the scanner tab will show a retryable state.
        }
      }
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E1F25), Color(0xFF1B1B22)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF393A44)),
    );
  }

  Widget _buildToolsHeader(String language) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('tools', language),
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6D7BFF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.get('toolsHeaderSubtitle', language),
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolsTabBar(String language) {
    final tabs = [
      (AppStrings.get('qrGenerator', language), Icons.qr_code_rounded),
      (AppStrings.get('scanQR', language), Icons.qr_code_scanner_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF22232A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF333542)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedToolTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setToolTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFFD1BFFF), Color(0xFFB39EEA)],
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
                      color: selected ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tabs[index].$1,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQrTab(QRProvider provider) {
    final language = _language;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('yourInfo'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF23242C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: const Icon(Icons.qr_code_rounded, color: Colors.white54),
                    hintText: _t('enterText'),
                    hintStyle: const TextStyle(color: Colors.white54),
                  ),
                  onChanged: provider.setUrl,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  (_t('qrTemplateUrl'), 'url'),
                  (_t('qrTemplateEmail'), 'email'),
                  (_t('qrTemplatePhone'), 'phone'),
                  (_t('qrTemplateSms'), 'sms'),
                  (_t('qrTemplateWifi'), 'wifi'),
                ].map((e) {
                  return OutlinedButton.icon(
                    onPressed: () => _applyTemplate(e.$2),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(e.$1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      backgroundColor: const Color(0xFF2A2B35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t('qrAdvancedContentComingSoon'))),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(_t('qrAdvancedContentBuilder')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCAB8FF),
                    side: const BorderSide(color: Colors.white30),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D7BFF), Color(0xFF8A56C7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: provider.generateQR,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      AppStrings.get('createQR', language),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _urlController.text.trim()),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_t('qrContentCopied'))),
                        );
                      },
                      icon: const Icon(Icons.copy_all_rounded),
                      label: Text(_t('qrCopyContent')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _urlController.clear();
                        provider.setUrl('');
                      },
                      icon: const Icon(Icons.clear_rounded),
                      label: Text(_t('qrClearInput')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('qrStyleSettings'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                _t('qrStylePresets'),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _qrStyles.map((style) {
                  return ChoiceChip(
                    selected: _selectedQrStyle == style,
                    label: Text(_styleLabel(style)),
                    onSelected: (_) => _applyStylePreset(style),
                    labelStyle: TextStyle(
                      color: _selectedQrStyle == style
                          ? Colors.white
                          : Colors.white70,
                    ),
                    selectedColor: const Color(0xFF6D7BFF),
                    backgroundColor: const Color(0xFF2A2B35),
                    side: BorderSide(
                      color: _selectedQrStyle == style
                          ? const Color(0xFFD1BFFF)
                          : Colors.white24,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                _t('qrErrorCorrectionLevel'),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF23242C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _errorLevel,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF23242C),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    iconEnabledColor: Colors.white70,
                    items: const [
                      DropdownMenuItem(
                        value: QrErrorCorrectLevel.L,
                        child: Text('L (%7)'),
                      ),
                      DropdownMenuItem(
                        value: QrErrorCorrectLevel.M,
                        child: Text('M (%15)'),
                      ),
                      DropdownMenuItem(
                        value: QrErrorCorrectLevel.Q,
                        child: Text('Q (%25)'),
                      ),
                      DropdownMenuItem(
                        value: QrErrorCorrectLevel.H,
                        child: Text('H (%30)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _errorLevel = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_t('qrSizeLabel')}: ${_qrSize.toStringAsFixed(0)} px',
                style: const TextStyle(color: Colors.white70),
              ),
              Slider(
                value: _qrSize,
                min: 160,
                max: 340,
                onChanged: (v) => setState(() => _qrSize = v),
              ),
              Text(
                '${_t('qrInnerSpacingLabel')}: ${_innerSpacing.toStringAsFixed(0)} px',
                style: const TextStyle(color: Colors.white70),
              ),
              Slider(
                value: _innerSpacing,
                min: 0,
                max: 42,
                onChanged: (v) => setState(() => _innerSpacing = v),
              ),
              Text(
                '${_t('qrCornerRadiusLabel')}: ${_borderRadius.toStringAsFixed(0)} px',
                style: const TextStyle(color: Colors.white70),
              ),
              Slider(
                value: _borderRadius,
                min: 0,
                max: 24,
                onChanged: (v) => setState(() => _borderRadius = v),
              ),
              Text(
                '${_t('qrBorderThicknessLabel')}: ${_borderThickness.toStringAsFixed(1)} px',
                style: const TextStyle(color: Colors.white70),
              ),
              Slider(
                value: _borderThickness,
                min: 0,
                max: 14,
                onChanged: (v) => setState(() => _borderThickness = v),
              ),
              Text(
                '${_t('qrBorderShadowLabel')}: ${_borderShadow.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Slider(
                value: _borderShadow,
                min: 0,
                max: 24,
                onChanged: (v) => setState(() => _borderShadow = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: !_eyeCircle,
                      label: Text(_t('qrEyeSquare')),
                      onSelected: (_) => setState(() => _eyeCircle = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: _eyeCircle,
                      label: Text(_t('qrEyeCircle')),
                      onSelected: (_) => setState(() => _eyeCircle = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: !_dataCircle,
                      label: Text(_t('qrDataSquare')),
                      onSelected: (_) => setState(() => _dataCircle = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: _dataCircle,
                      label: Text(_t('qrDataCircle')),
                      onSelected: (_) => setState(() => _dataCircle = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _t('qrLeaveModuleGap'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _leaveModuleGap,
                    onChanged: (v) => setState(() => _leaveModuleGap = v),
                    activeThumbColor: const Color(0xFFD1BFFF),
                  ),
                ],
              ),
              Text(
                '${_t('qrContentLength')}: ${provider.url.length} ${_t('qrCharacters')}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 10),
              Text(
                _t('qrCenterImageTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['none', 'appLogo', 'custom'].map((item) {
                  return ChoiceChip(
                    selected: _centerImage == item,
                    label: Text(_centerImageLabel(item)),
                    onSelected: (_) async {
                      if (item == 'custom') {
                        await _pickCustomCenterImage();
                        return;
                      }

                      setState(() {
                        _centerImage = item;
                      });
                    },
                  );
                }).toList(),
              ),
              if (_centerImage == 'custom' && _customCenterImageFile == null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    _t('qrCenterImageHint'),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                '${_t('qrExportQuality')}: x${_exportQuality.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Slider(
                value: _exportQuality,
                min: 1.0,
                max: 6.0,
                onChanged: (v) => setState(() => _exportQuality = v),
              ),
              Text(
                '${_t('qrErrorCorrectionLevel')}: ${_errorLevelText(_errorLevel)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: _qrSize,
                  height: _qrSize,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: _borderThickness > 0
                        ? Border.all(
                            color: _foregroundColor,
                            width: _borderThickness,
                          )
                        : null,
                    boxShadow: _borderShadow > 0
                        ? [
                            BoxShadow(
                              color: _foregroundColor.withValues(alpha: 0.28),
                              blurRadius: _borderShadow,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  padding: EdgeInsets.all(_innerSpacing),
                  child: provider.qrModel == null
                      ? Center(
                          child: Icon(
                            Icons.qr_code_2,
                            color: _foregroundColor.withValues(alpha: 0.25),
                            size: 56,
                          ),
                        )
                      : RepaintBoundary(
                          key: _qrImageKey,
                          child: QrImageView(
                            data: provider.qrModel!.url,
                            version: QrVersions.auto,
                            size: _qrSize - (_innerSpacing * 2),
                            backgroundColor: _backgroundColor,
                            gapless: !_leaveModuleGap,
                            errorCorrectionLevel: _errorLevel,
                            eyeStyle: QrEyeStyle(
                              color: _foregroundColor,
                              eyeShape: _eyeCircle
                                  ? QrEyeShape.circle
                                  : QrEyeShape.square,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              color: _foregroundColor,
                              dataModuleShape: _dataCircle
                                  ? QrDataModuleShape.circle
                                  : QrDataModuleShape.square,
                            ),
                            embeddedImage: _embeddedImageProvider(provider),
                            embeddedImageStyle: const QrEmbeddedImageStyle(
                              size: Size(42, 42),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('qrForegroundColor'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _palette.map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => _foregroundColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: _foregroundColor == c
                                ? const Color(0xFFD1BFFF)
                                : Colors.white30,
                            width: _foregroundColor == c ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showColorPicker('foreground'),
                icon: const Icon(Icons.colorize_rounded),
                label: Text('${_t('qrSelectColor')} (${_hexColor(_foregroundColor)})'),
              ),
              const SizedBox(height: 10),
              Text(
                _t('qrBackgroundColor'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _palette.map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => _backgroundColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: _backgroundColor == c
                                ? const Color(0xFFD1BFFF)
                                : Colors.white30,
                            width: _backgroundColor == c ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showColorPicker('background'),
                icon: const Icon(Icons.colorize_rounded),
                label: Text('${_t('qrSelectColor')} (${_hexColor(_backgroundColor)})'),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2B35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _t('qrContrastGood'),
                  style: const TextStyle(
                    color: Color(0xFFBCEFB8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareQrPng,
                icon: const Icon(Icons.share_outlined),
                label: Text(AppStrings.get('shareQR', language)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveQrPng,
                icon: const Icon(Icons.download_rounded),
                label: Text(AppStrings.get('saveQR', language)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrScannerTab(String language) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 360,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3A3B48)),
              color: const Color(0xFF12131A),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleLiveDetection,
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.16),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE7D9FF), width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.get('qrScannerTitle', language),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('qrScannerSubtitle', language),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.white60),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _pickAndScanFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(AppStrings.get('scanFromGallery', language)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_lastScannedValue != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_t('qrLastScanned')}: $_lastScannedValue',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QRProvider>(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final language = themeProvider.language;

        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: const Color(0xFF09090C),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToolsHeader(language),
                      const SizedBox(height: 18),
                      _buildToolsTabBar(language),
                      const SizedBox(height: 20),
                      if (_selectedToolTab == 0)
                        _buildQrTab(provider)
                      else
                        _buildQrScannerTab(language),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
