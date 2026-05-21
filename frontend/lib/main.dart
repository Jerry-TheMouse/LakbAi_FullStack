// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Providers Integration Layer
import 'providers/auth_provider.dart';
import 'providers/destinations_provider.dart';
import 'providers/itinerary_provider.dart';
import 'providers/admin_provider.dart';

// Screens Implementation Layer
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/destinations_screen.dart';
import 'screens/add_destination_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/admin_request_details_screen.dart';
import 'widgets/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local caching Hive framework configurations
  await Hive.initFlutter();
  await Hive.openBox('destinationsBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => DestinationsProvider()),
        ChangeNotifierProvider(create: (_) => ItineraryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const LakbAiApp(),
    ),
  );
}

class LakbAiApp extends StatelessWidget {
  const LakbAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Secure declarative routing layer shell configuration
    final GoRouter router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (authProvider.isLoading) return null;

        final loggedIn = authProvider.user != null;
        final goingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

        if (!loggedIn && !goingToAuth && state.matchedLocation != '/') {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        
        // --- ADDED THIS NEW ROUTE TO FIX "PAGE NOT FOUND" (404) ---
        GoRoute(
          path: '/details',
          builder: (context, state) {
            final requestObj = state.extra as Map<String, dynamic>? ?? {};
            return AdminRequestDetailsScreen(request: requestObj);
          },
        ),

        // Admin details deep link isolated from shell standard viewport views
        GoRoute(
          path: '/admin-request-details',
          builder: (context, state) {
            final requestObj = state.extra as Map<String, dynamic>? ?? {};
            return AdminRequestDetailsScreen(request: requestObj);
          },
        ),

        // Navigation Layout Architecture Shell Route core
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
            GoRoute(path: '/planner', builder: (context, state) => const PlannerScreen()),
            GoRoute(path: '/destinations', builder: (context, state) => const DestinationsScreen()),
            GoRoute(path: '/add-destination', builder: (context, state) => const AddDestinationScreen()),
            GoRoute(path: '/requests', builder: (context, state) => const RequestsScreen()),
            GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'LakbAi FullStack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      routerConfig: router,
    );
  }
}