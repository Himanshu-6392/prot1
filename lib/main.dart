import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/firebase_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_animate/flutter_animate.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<void> main() async {
  Animate.restartOnHotReload = true;
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait and landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set light theme palette by default
  AppColors.setLight();

  // System UI overlay — light status bar for light theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  


  // Hive local cache
  debugPrint('Initializing Hive...');
  await Hive.initFlutter();
  debugPrint('Opening Hive box...');
  await Hive.openBox('settings');
  debugPrint('Hive box opened successfully!');

  debugPrint('Calling runApp...');
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    isToolbarVisible: false,
    defaultDevice: Devices.ios.iPhone13,
    builder: (context) => const ProviderScope(child: PeerLendApp()),
  ));
  debugPrint('runApp called!');
}

class PeerLendApp extends ConsumerStatefulWidget {
  const PeerLendApp({super.key});

  @override
  ConsumerState<PeerLendApp> createState() => _PeerLendAppState();
}

class _PeerLendAppState extends ConsumerState<PeerLendApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    debugPrint('PeerLendApp initState...');
    WidgetsBinding.instance.addObserver(this);
    // Trigger initial auth if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeviceLock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Lock on every transition away from foreground:
      // • inactive  → phone screen off / call overlay / app switcher
      // • paused    → app fully in background
      // • hidden    → Flutter 3.13+ (pre-paused, window hidden)
      // • detached  → process kept alive but no view
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        ref.read(securityProvider.notifier).lockSensitiveData();
        break;
      case AppLifecycleState.resumed:
        // Nothing — user must re-enter PIN manually via the blur tap
        break;
    }
  }

  Future<void> _checkDeviceLock() async {
    final isLoggedIn = ref.read(currentUserProvider).valueOrNull != null;
    if (isLoggedIn) {
      // Assuming authenticateWithDevice handles its own UI (native overlay)
      await ref.read(securityProvider.notifier).authenticateWithDevice(
            'Please authenticate to unlock PeerLend',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PeerLendApp build...');
    final router = ref.watch(routerProvider);

    // Sync AppColors static palette with the active theme mode.
    // This must happen BEFORE the widget tree is built so every
    // widget reading AppColors.* picks up the correct values.
    final themeMode = ref.watch(themeModeProvider);
    if (themeMode == ThemeMode.dark) {
      AppColors.setDark();
    } else {
      AppColors.setLight();
    }

    return MaterialApp.router(
      title: 'PeerLend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
