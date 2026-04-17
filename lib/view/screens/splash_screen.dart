import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/services/app_launcher_service.dart';
import '../../data/services/app_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  final AppStorageService _storageService = AppStorageService();
  String _language = 'tr';
  String _randomTip = '';
  bool _hasNavigated = false;
  bool _isOffline = false;
  bool _isRetryingConnection = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..forward();

    _loadLanguage();
    _startNavigationTimer();
  }

  Future<void> _loadLanguage() async {
    final language = await _storageService.getLanguage();
    _selectRandomTip(language);
    if (!mounted) {
      return;
    }
    setState(() {
      _language = language;
    });
  }

  void _selectRandomTip(String language) {
    const tips = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
    ];
    final random = Random();
    final randomTipNumber = tips[random.nextInt(tips.length)];
    _randomTip = AppStrings.get('tip$randomTipNumber', language);
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted || _hasNavigated) {
        return;
      }

      final hasInternet = await AppLauncherService.hasInternetConnection();
      if (!mounted) {
        return;
      }

      if (!hasInternet) {
        setState(() {
          _isOffline = true;
        });
        return;
      }

      _hasNavigated = true;

      try {
        final isProfileCreated = await _storageService.isProfileCreated();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            isProfileCreated ? '/' : '/profile',
            (route) => false,
          );
        }
      } catch (_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    });
  }

  Future<void> _retryWithInternetCheck() async {
    if (_isRetryingConnection || _hasNavigated) {
      return;
    }

    setState(() {
      _isRetryingConnection = true;
    });

    try {
      final hasInternet = await AppLauncherService.hasInternetConnection();
      if (!mounted) {
        return;
      }

      if (!hasInternet) {
        setState(() {
          _isOffline = true;
          _isRetryingConnection = false;
        });
        return;
      }

      setState(() {
        _isOffline = false;
      });

      _navigationTimer?.cancel();
      _startNavigationTimer();
    } finally {
      if (mounted) {
        setState(() {
          _isRetryingConnection = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF07070B),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181820),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C2C3A)),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 44,
                        color: Color(0xFFFF8A80),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppStrings.get('internetRequiredTitle', _language),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.get('internetRequiredDesc', _language),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRetryingConnection
                            ? null
                            : _retryWithInternetCheck,
                        icon: _isRetryingConnection
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(AppStrings.get('retryNow', _language)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFF8A7DFF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF07070B),
        body: Stack(
          children: [
            const _SplashBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    ScaleTransition(
                      scale: Tween(begin: 0.88, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _SplashLogo(),
                          const SizedBox(height: 28),
                          Text(
                            AppStrings.get('appName', _language),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.get('splashSubtitle', _language),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF17171F),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF2D2D3D),
                              ),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF8A7DFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.get('splashLoading', _language),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.74),
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    Material(
                      color: const Color(0xFF14141B),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF2B2B39)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A7DFF).withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF8A7DFF,
                                    ).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.tips_and_updates_outlined,
                                    color: Color(0xFFB7A8FF),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _randomTip.isEmpty
                                        ? AppStrings.get('loading', _language)
                                        : _randomTip,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.get('splashTagline', _language),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.get('developer', _language),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.get('allRightsReserved', _language),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -70,
          child: _GlowBlob(
            color: const Color(0xFF8A7DFF).withOpacity(0.26),
            size: 180,
          ),
        ),
        Positioned(
          top: 120,
          right: -50,
          child: _GlowBlob(
            color: const Color(0xFF5FB6FF).withOpacity(0.18),
            size: 140,
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _SplashGridPainter())),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D7BFF), Color(0xFF8A7DFF), Color(0xFF55C5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A7DFF).withOpacity(0.42),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.22), Colors.transparent],
                  center: const Alignment(-0.55, -0.7),
                  radius: 0.95,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2B2B39).withOpacity(0.25)
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
