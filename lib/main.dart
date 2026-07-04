import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/firebase_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/theme/text_styles.dart';
import 'firebase_options.dart';

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
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: PeerLendApp()));
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Re-blur sensitive data when it goes to background
      final isLogged = ref.read(firebaseAuthProvider).currentUser != null;
      if (isLogged) {
        ref.read(securityProvider.notifier).lockSensitiveData();
      }
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
      builder: (context, child) {
        final textScaler = MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2);
        
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaler),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
