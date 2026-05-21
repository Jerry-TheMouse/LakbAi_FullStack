import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // NEW: State variable to track password visibility
  bool _obscurePassword = true; 
  
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5), // Light emerald background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.map, size: 48, color: Color(0xFF059669)),
                const SizedBox(height: 16),
                const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                const SizedBox(height: 8),
                const Text('Log in to continue your journey', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(LucideIcons.mail, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // NEW: Controlled by our variable
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    // NEW: The clickable Eye Icon
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SIGN IN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("Don't have an account? Sign up", style: TextStyle(color: Color(0xFF059669))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}