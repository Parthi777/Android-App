import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_business_manager/firebase_options.dart';

// Theme & Services
import 'package:ai_business_manager/theme/app_theme.dart';
import 'package:ai_business_manager/providers/theme_provider.dart';
import 'package:ai_business_manager/services/auth_service.dart';

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

  // Initialize Firebase (Requires flutterfire configure)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed (maybe no options file): $e");
  }

  runApp(
    // Wrap the app with ProviderScope for Riverpod
    const ProviderScope(child: AIBusinessManagerApp()),
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
              builder: (context, state) => const EnquiryPage(),
            ),
            GoRoute(
              path: '/sales/bookings',
              builder: (context, state) => const BookingsPage(),
            ),
            GoRoute(
              path: '/sales/sold',
              builder: (context, state) => const SoldPage(),
            ),
            GoRoute(
              path: '/stock',
              builder: (context, state) => const StockPage(),
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
