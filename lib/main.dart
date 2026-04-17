import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'core/navigation/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'di/injection_container.dart' as di;
import 'presentation/providers/message_provider.dart';
import 'presentation/providers/qr_provider.dart';
import 'presentation/providers/qr_scanner_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_profile_provider.dart';
import 'presentation/providers/scan_history_provider.dart';
import 'presentation/providers/authentication_provider.dart';
import 'data/services/hive_service.dart';
import 'view/screens/splash_screen.dart';
import 'view/screens/profile_creation_screen.dart';
import 'view/screens/profile_detail_screen.dart';
import 'view/screens/home_screen.dart';
import 'view/screens/message_screen.dart';
import 'view/screens/qr_screen.dart';
import 'view/screens/search_history_screen.dart';
import 'view/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Web'de Hive desteği farklı
    if (!kIsWeb) {
      await HiveService.initialize();
    } else {
      debugPrint(
        'Web platformu: Hive geçici almıyor (SharedPreferences kullanılıyor)',
      );
    }
    await di.setupDependencies();
  } catch (e) {
    debugPrint('Initialization error: $e');
    // Hata olsa bile devam et
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => di.getIt<MessageProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<QRProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<QRScannerProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<UserProfileProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<ScanHistoryProvider>()),
        ChangeNotifierProvider(
          create: (_) => di.getIt<AuthenticationProvider>(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // ThemeProvider initialize olmadan bekle
          if (!themeProvider.isInitialized) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'FastGokdeniz',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light,
            navigatorKey: NavigationService.navigatorKey,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/profile': (context) => const ProfileCreationScreen(),
              '/profile-detail': (context) => const ProfileDetailScreen(),
              '/': (context) => const HomeScreen(),
              '/message': (context) => const MessageScreen(),
              '/qr': (context) => const QRScreen(),
              '/history': (context) => const SearchHistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
