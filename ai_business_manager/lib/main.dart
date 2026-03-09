import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ai_business_manager/services/background_notification_service.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_business_manager/firebase_options.dart';

// Theme & Services
import 'package:ai_business_manager/theme/app_theme.dart';
import 'package:ai_business_manager/providers/theme_provider.dart';
import 'package:ai_business_manager/services/auth_service.dart';
import 'package:ai_business_manager/services/google_sheet_service.dart';
import 'package:ai_business_manager/core/app_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

// UI Layout & Pages
import 'package:ai_business_manager/widgets/app_layout.dart';
import 'package:ai_business_manager/pages/auth/auth_page.dart';
import 'package:ai_business_manager/pages/dashboard/dashboard_page.dart';
import 'package:ai_business_manager/pages/sales/enquiry_page.dart';
import 'package:ai_business_manager/pages/sales/bookings_page.dart';
import 'package:ai_business_manager/pages/sales/sold_page.dart';
import 'package:ai_business_manager/pages/stock/stock_page.dart';
import 'package:ai_business_manager/pages/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mvjjtkfbndddkbxnufdh.supabase.co',
    anonKey: 'sb_publishable_Ki1DWv4mvUdJb-gd3WlABA_NeiTnxz7',
  );

  // Initialize Firebase (Requires flutterfire configure)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed (maybe no options file): $e");
  }

  // Create a container so we can read providers
  final container = ProviderContainer();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final appCache = AppCache(prefs);

  // Initialize Google Sheets API
  try {
    final sheetService = container.read(googleSheetServiceProvider);
    await sheetService.initialize('assets/credentials.json');
  } catch (e) {
    debugPrint("Google Sheets init failed: $e");
  }

  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    "dataFreshnessCheck",
    "dataFreshnessTask",
    frequency: const Duration(hours: 2),
    initialDelay: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(
    // Wrap the app with ProviderScope
    UncontrolledProviderScope(
      container: container,
      child: ProviderScope(
        overrides: [appCacheProvider.overrideWithValue(appCache)],
        child: const AIBusinessManagerApp(),
      ),
    ),
  );
}

class AIBusinessManagerApp extends ConsumerWidget {
  const AIBusinessManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Theme dynamically
    final themeMode = ref.watch(themeProvider);

    final goRouter = GoRouter(
      initialLocation: '/auth',
      redirect: (context, state) {
        // We look at Firebase synchronous currentUser to decide initially
        // Ideally we listen to a StreamProvider for real auth redirection.
        final user = ref.read(authServiceProvider).currentUser;
        final isAuthPath = state.uri.path == '/auth';

        if (user == null && !isAuthPath) return '/auth';
        if (user != null && isAuthPath) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
        ShellRoute(
          builder: (context, state, child) => AppLayout(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/sales/enquiry',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return EnquiryPage(
                  preFilterData: extra?['preFilterData'],
                  drillDownTitle: extra?['drillDownTitle'],
                  initialDateRange: extra?['initialDateRange'],
                );
              },
            ),
            GoRoute(
              path: '/sales/bookings',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return BookingsPage(
                  preFilterData: extra?['preFilterData'],
                  drillDownTitle: extra?['drillDownTitle'],
                  initialDateRange: extra?['initialDateRange'],
                );
              },
            ),
            GoRoute(
              path: '/sales/sold',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return SoldPage(
                  preFilterData: extra?['preFilterData'],
                  drillDownTitle: extra?['drillDownTitle'],
                  initialDateRange: extra?['initialDateRange'],
                );
              },
            ),
            GoRoute(
              path: '/stock',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return StockPage(
                  preFilterData: extra?['preFilterData'],
                  drillDownTitle: extra?['drillDownTitle'],
                );
              },
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Dhaara Business Manager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
