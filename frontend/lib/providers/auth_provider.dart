import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  final _storage = const FlutterSecureStorage();

  Future<void> initAuth() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final savedUser = await _storage.read(key: 'user_data');
      if (token != null && savedUser != null) {
        _user = jsonDecode(savedUser);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, String role, String region, String contactNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'region': region,
          'contactNumber': contactNumber,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
      } else {
        throw Exception('Invalid credentials');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_data');
    notifyListeners();
  }
}