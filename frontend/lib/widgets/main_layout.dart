import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';


class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Get current route to highlight the active tab
    final String location = GoRouterState.of(context).matchedLocation;

    // Define the tabs based on user roles (just like your Layout.jsx)
    final List<Map<String, dynamic>> navItems = [
      {'name': 'Home', 'path': '/', 'icon': LucideIcons.home, 'show': true},
      {'name': 'Explore', 'path': '/explore', 'icon': LucideIcons.map, 'show': user != null && !authProvider.isAdmin && !authProvider.isTourismOffice},
      {'name': 'Planner', 'path': '/planner', 'icon': LucideIcons.calendar, 'show': user != null && !authProvider.isAdmin && !authProvider.isTourismOffice},
      {'name': 'Destinations', 'path': '/destinations', 'icon': LucideIcons.mapPin, 'show': authProvider.isTourismOffice},
      {'name': 'Requests', 'path': '/requests', 'icon': LucideIcons.inbox, 'show': authProvider.isAdmin},
      {'name': 'Analytics', 'path': '/analytics', 'icon': LucideIcons.barChart3, 'show': authProvider.isAdmin || authProvider.isTourismOffice},
    ];

    // Filter to only show visible items
    final visibleItems = navItems.where((item) => item['show'] == true).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Let the child screen background show
      body: child, // This is where HomeScreen, LoginScreen, etc. will appear
      
      // MODERN MOBILE BOTTOM NAV (Only show if logged in, or adjust as needed)
      bottomNavigationBar: visibleItems.length > 1 ? Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: visibleItems.map((item) {
                final isActive = location == item['path'];
                return InkWell(
                  onTap: () => context.go(item['path']),
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF059669) : Colors.transparent, // Emerald 600
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'],
                          color: isActive ? Colors.white : const Color(0xFF059669),
                          size: 20,
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Text(
                            item['name'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ) : null,
    );
  }
}