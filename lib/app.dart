import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/auth_provider.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/login_screen.dart';
import 'features/onboarding/screens/pin_lock_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/transactions/screens/transactions_list_screen.dart';
import 'features/transactions/screens/new_transaction_screen.dart';
import 'features/customers/screens/customers_list_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/products/screens/products_screen.dart';
import 'features/audit/screens/audit_logs_screen.dart';
import 'features/settings/screens/users_screen.dart';
import 'features/settings/screens/business_settings_screen.dart';
import 'features/settings/screens/security_settings_screen.dart';
import 'features/customers/screens/customer_detail_screen.dart';
import 'features/transactions/screens/transaction_detail_screen.dart';
import 'features/transactions/screens/collect_payment_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      if (location == '/splash') return null;

      if (!isAuthenticated && location != '/login') {
        return '/login';
      }

      if (isAuthenticated && (location == '/login' || location == '/splash')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashWrapper(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pin-lock',
        builder: (context, state) => const PinLockScreen(mode: PinMode.verify),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinLockScreen(mode: PinMode.setup),
      ),
      GoRoute(
        path: '/pin-confirm',
        builder: (context, state) {
          final setupPin = state.extra as String?;
          return PinLockScreen(mode: PinMode.confirm, setupPin: setupPin);
        },
      ),

      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsListScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersListScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: '/transactions/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewTransactionScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transactions/:id/collect',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CollectPaymentScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Add Customer')),
          body: const Center(child: Text('Add customer screen — coming soon')),
        ),
      ),
      GoRoute(
        path: '/customers/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CustomerDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/products',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/audit-logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/settings/business',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BusinessSettingsScreen(),
      ),
    ],
  );
});

class OneWaterApp extends ConsumerStatefulWidget {
  const OneWaterApp({super.key});

  @override
  ConsumerState<OneWaterApp> createState() => _OneWaterAppState();
}

class _OneWaterAppState extends ConsumerState<OneWaterApp> with WidgetsBindingObserver {
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final storage = ref.read(secureStorageProvider);
      final lastActive = await storage.getLastActive();
      
      // If inactive for more than 1 minute, require PIN
      if (lastActive != null && DateTime.now().difference(lastActive).inMinutes >= 1) {
        final pin = await storage.getAppPin();
        if (pin != null && pin.isNotEmpty) {
          final router = ref.read(routerProvider);
          // Only push if not already on PIN screen or login
          final location = router.routerDelegate.currentConfiguration.last.matchedLocation;
          if (!location.startsWith('/pin') && location != '/login' && location != '/splash') {
            router.push('/pin-lock');
          }
        }
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final storage = ref.read(secureStorageProvider);
      await storage.setLastActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OneWater Pakistan',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Splash wrapper — auto-navigates after auth check
class _SplashWrapper extends ConsumerStatefulWidget {
  const _SplashWrapper();

  @override
  ConsumerState<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<_SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await ref.read(authStateProvider.notifier).checkAuthStatus();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
    if (isAuthenticated) {
      final storage = ref.read(secureStorageProvider);
      final pin = await storage.getAppPin();
      if (pin != null && pin.isNotEmpty) {
        if (mounted) context.go('/pin-lock');
      } else {
        if (mounted) context.go('/dashboard');
      }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// Main shell with bottom navigation
class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/more')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/transactions'); break;
            case 2: context.go('/customers'); break;
            case 3: context.go('/more'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
