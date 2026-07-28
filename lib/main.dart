import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/firebase_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<void> main() async {
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
  
  // --- TEMPORARY DB CLEANUP ---
  try {
    final matchSnap = await FirebaseFirestore.instance.collection('matches').get();
    
    // Deduplicate matches based on borrowerId + lenderId
    final Map<String, List<QueryDocumentSnapshot>> matchGroups = {};
    for (final doc in matchSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String bId = data['borrowerId'] ?? '';
      final String lId = data['lenderId'] ?? '';
      final key = '${bId}_$lId';
      if (!matchGroups.containsKey(key)) {
        matchGroups[key] = [];
      }
      matchGroups[key]!.add(doc);
    }
    
    // Clean up orphaned matches
    for (final key in matchGroups.keys) {
      final docs = matchGroups[key]!;
      // Delete duplicates first
      if (docs.length > 1) {
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final tA = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });
        
        for (int i = 1; i < docs.length; i++) {
          await docs[i].reference.delete();
        }
      }
      
      // For the remaining match, check if lender exists
      final remainingDoc = docs.first;
      final lenderId = (remainingDoc.data() as Map<String, dynamic>)['lenderId'] ?? '';
      
      final lenderDoc = await FirebaseFirestore.instance.collection('lenders').doc(lenderId).get();
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(lenderId).get();
      
      if (!lenderDoc.exists && !userDoc.exists) {
        await remainingDoc.reference.delete();
        print('Deleted orphaned match with unknown lender: ${remainingDoc.id}');
      }
    }
  } catch (e) {
    print('Cleanup error: $e');
  }
  // -----------------------------

  // Hive local cache
  print('Initializing Hive...');
  await Hive.initFlutter();
  print('Opening Hive box...');
  await Hive.openBox('settings');
  print('Hive box opened successfully!');

  print('Calling runApp...');
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    isToolbarVisible: false,
    builder: (context) => const ProviderScope(child: PeerLendApp()),
  ));
  print('runApp called!');
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
    print('PeerLendApp initState...');
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
    print('PeerLendApp build...');
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PeerLend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
