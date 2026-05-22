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
  final _contactController = TextEditingController();
  
  bool _obscurePassword = true;
  String _selectedRole = 'tourist'; // Matched to DB
  String _selectedRegion = 'Luzon'; 
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
        _selectedRegion,
        _contactController.text.trim(),
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
      backgroundColor: const Color(0xFF064E3B),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                const SizedBox(height: 20),
                
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(LucideIcons.user))),
                const SizedBox(height: 10),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(LucideIcons.mail))),
                const SizedBox(height: 10),
                TextField(controller: _passwordController, obscureText: _obscurePassword, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(LucideIcons.lock))),
                const SizedBox(height: 10),
                TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(LucideIcons.phone))),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'tourist', child: Text('Tourist')),
                    DropdownMenuItem(value: 'tourism_office', child: Text('Tourism Office')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(labelText: 'Region'),
                  items: const [
                    DropdownMenuItem(value: 'Luzon', child: Text('Luzon')),
                    DropdownMenuItem(value: 'Visayas', child: Text('Visayas')),
                    DropdownMenuItem(value: 'Mindanao', child: Text('Mindanao')),
                  ],
                  onChanged: (v) => setState(() => _selectedRegion = v!),
                ),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF064E3B)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER', style: TextStyle(color: Colors.white)),
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