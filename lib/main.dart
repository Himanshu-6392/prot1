import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/firebase_providers.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';
import 'scripts/fix_user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait and landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // System UI overlay
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarBrightness:     Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Hive local cache
  await Hive.initFlutter();

  runApp(DevicePreview(
    enabled: true,
    builder: (context) => const ProviderScope(child: PeerLendApp()),
  ));
}

class PeerLendApp extends ConsumerStatefulWidget {
  const PeerLendApp({super.key});

  @override
  ConsumerState<PeerLendApp> createState() => _PeerLendAppState();
}

class _PeerLendAppState extends ConsumerState<PeerLendApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
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
    if (state == AppLifecycleState.paused) {
      // Re-blur sensitive data when app goes to background
      ref.read(securityProvider.notifier).lockSensitiveData();
    } else if (state == AppLifecycleState.resumed) {
      // Authenticate with device lock when coming back
      _checkDeviceLock();
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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title:              'PeerLend',
      debugShowCheckedModeBanner: false,
      theme:              AppTheme.dark,
      routerConfig:       router,
      locale:             DevicePreview.locale(context),
      builder: (context, child) {
        final dpChild = DevicePreview.appBuilder(context, child);
        // Global text scale constraint — prevents huge text on accessibility settings
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: dpChild,
        );
      },
    );
  }
}
