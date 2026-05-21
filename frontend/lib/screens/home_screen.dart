// frontend/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.user != null;

    return Scaffold(
      // Drawer implementation for cleaner profile navigation controls
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(isLoggedIn ? (authProvider.user!['name'] ?? 'User Profile') : 'Guest Explorer'),
              accountEmail: Text(isLoggedIn ? (authProvider.user!['email'] ?? '') : 'Log in to unlock features'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(LucideIcons.user, color: Color(0xFF059669), size: 32),
              ),
              decoration: const BoxDecoration(color: Color(0xFF064E3B)),
            ),
            if (isLoggedIn) ...[
              ListTile(
                leading: const Icon(LucideIcons.shieldCheck, color: Color(0xFF059669)),
                title: Text('Account Role: ${authProvider.user!['role'].toString().toUpperCase()}'),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: Colors.red),
                title: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ] else ...[
              ListTile(
                leading: const Icon(LucideIcons.logIn, color: Color(0xFF059669)),
                title: const Text('Sign In Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
              ),
            ]
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Media Cover Container Layout
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF064E3B),
              image: DecorationImage(
                image: AssetImage('assets/images/hero-bg.jpg'),
                fit: BoxFit.cover,
                opacity: 0.25,
              ),
            ),
          ),
          
          // Header Actions Appbar overlay configuration
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(LucideIcons.menu, color: Colors.white, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Text(
                    'LakbAi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                  ),
                  const SizedBox(width: 40), // Balanced spacers constraint
                ],
              ),
            ),
          ),

          // Central Messaging Content Layout Screen Core
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Explore the Beauty of the Philippines',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Plan your customized itineraries seamlessly using production-grade AI offline models.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  
                  // Interactive Action Routing Core Panels
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/explore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('BROWSE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/planner'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ITINERARY AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}