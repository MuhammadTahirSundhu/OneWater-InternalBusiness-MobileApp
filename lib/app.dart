import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/auth_provider.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/login_screen.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Transaction Details')),
          body: const Center(child: Text('Transaction detail screen — coming soon')),
        ),
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Customer Details')),
          body: const Center(child: Text('Customer detail screen — coming soon')),
        ),
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(child: Text('Settings screen — coming soon')),
        ),
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

class OneWaterApp extends ConsumerWidget {
  const OneWaterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      context.go('/dashboard');
    } else {
      context.go('/login');
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
