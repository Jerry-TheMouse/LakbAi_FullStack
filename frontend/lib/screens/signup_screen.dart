import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // NEW: State variable for password visibility
  bool _obscurePassword = true;
  
  String _selectedRole = 'user'; // Default to Tourist
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
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
      backgroundColor: const Color(0xFF064E3B), // Dark emerald for signup
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                const SizedBox(height: 24),
                
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(LucideIcons.user, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
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
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Account Type',
                    prefixIcon: const Icon(LucideIcons.briefcase, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Tourist')),
                    DropdownMenuItem(value: 'tourism_office', child: Text('Tourism Office')),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('REGISTER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}