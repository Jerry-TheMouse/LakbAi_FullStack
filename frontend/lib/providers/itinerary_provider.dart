import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../config.dart'; // <-- Import centralized config

class ItineraryProvider extends ChangeNotifier {
  List<dynamic> _itineraries = [];
  bool _isLoading = false;
  String _currentAiResult = ''; 

  List<dynamic> get itineraries => _itineraries;
  bool get isLoading => _isLoading;
  String get currentAiResult => _currentAiResult;
  
  final _box = Hive.box('destinationsBox'); 
  final _secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchSavedItineraries() async {
    final cached = _box.get('cached_itineraries');
    if (cached != null) {
      _itineraries = jsonDecode(cached);
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    try {
      await _syncPendingRequests(); 

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/itineraries'), // Centralized Base URL
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        _itineraries = jsonDecode(response.body);
        await _box.put('cached_itineraries', response.body); 
      }
    } catch (e) {
      debugPrint('Network execution timeout fallback.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addManualDestination(String destinationName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/itineraries'), // Centralized Base URL
        headers: headers,
        body: jsonEncode({
          'destination': destinationName,
          'days': 1,
          'budget': 'Flexible',
          'interests': ['Sightseeing'],
          'content': 'Manually added from Explore tab to visit later!'
        })
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) await fetchSavedItineraries(); 
    } catch (e) {
      final tempItem = {
        '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'destination': destinationName,
        'days': 1,
        'budget': 'Flexible',
        'interests': ['Sightseeing'],
        'content': 'Pending Sync: Connect to Wi-Fi to backup to database.'
      };
      _itineraries.insert(0, tempItem);
      await _box.put('cached_itineraries', jsonEncode(_itineraries));

      List<dynamic> pending = [];
      final storedPending = _box.get('pending_manual');
      if (storedPending != null) pending = jsonDecode(storedPending);
      pending.add(tempItem);
      await _box.put('pending_manual', jsonEncode(pending));

      notifyListeners();
    }
  }

  Future<void> generateItinerary(String destination, double days, String budget, List<String> interests) async {
    _isLoading = true;
    _currentAiResult = '';
    notifyListeners();

    final requestData = {
      'destination': destination,
      'days': days,
      'budget': budget,
      'interests': interests.isEmpty ? ['General'] : interests
    };

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/generate-itinerary'), // Centralized Base URL
        headers: headers,
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _currentAiResult = response.body;
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/itineraries'),
          headers: headers,
          body: jsonEncode({
            ...requestData,
            'content': _currentAiResult
          })
        );
        await fetchSavedItineraries();
      } else {
        _currentAiResult = 'Failed to generate itinerary. Server returned error.';
      }
    } catch (e) {
      _currentAiResult = 'Network Offline! AI requested. Connect to Wi-Fi to generate.';

      List<dynamic> pendingAi = [];
      final storedAi = _box.get('pending_ai');
      if (storedAi != null) pendingAi = jsonDecode(storedAi);
      pendingAi.add(requestData);
      await _box.put('pending_ai', jsonEncode(pendingAi));

      final tempItem = {
        '_id': 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        'destination': destination,
        'days': days,
        'budget': budget,
        'interests': requestData['interests'],
        'content': '⏳ AI Generation Queued. Connect to Wi-Fi and we will automatically write your itinerary in the background!'
      };
      _itineraries.insert(0, tempItem);
      await _box.put('cached_itineraries', jsonEncode(_itineraries));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItinerary(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/itineraries/$id'), // Centralized Base URL
        headers: headers
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _itineraries.removeWhere((item) => item['_id'] == id);
        await _box.put('cached_itineraries', jsonEncode(_itineraries));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delete queue action deferred.');
    }
  }

  Future<void> updateItinerary(String id, Map<String, dynamic> updatedData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/itineraries/$id'), // Centralized Base URL
        headers: headers,
        body: jsonEncode(updatedData),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) await fetchSavedItineraries();
    } catch (e) {
      debugPrint('Update queue action deferred.');
    }
  }

  Future<void> _syncPendingRequests() async {
    final headers = await _getHeaders();

    final storedManual = _box.get('pending_manual');
    if (storedManual != null) {
      List<dynamic> pendingManual = jsonDecode(storedManual);
      List<dynamic> stillPendingManual = [];

      for (var item in pendingManual) {
        try {
          final response = await http.post(
            Uri.parse('${AppConfig.baseUrl}/itineraries'),
            headers: headers,
            body: jsonEncode({
              'destination': item['destination'],
              'days': item['days'],
              'budget': item['budget'],
              'interests': item['interests'],
              'content': item['content'].toString().replaceAll('Pending Sync: Connect to Wi-Fi to backup to database.', 'Manually added from Explore tab to visit later!')
            })
          );
          if (response.statusCode != 201) stillPendingManual.add(item);
        } catch (e) {
          stillPendingManual.add(item);
        }
      }
      await _box.put('pending_manual', jsonEncode(stillPendingManual));
    }

    final storedAi = _box.get('pending_ai');
    if (storedAi != null) {
      List<dynamic> pendingAi = jsonDecode(storedAi);
      List<dynamic> stillPendingAi = [];

      for (var item in pendingAi) {
        try {
          final response = await http.post(
            Uri.parse('${AppConfig.baseUrl}/generate-itinerary'),
            headers: headers,
            body: jsonEncode(item),
          );

          if (response.statusCode == 200) {
            await http.post(
              Uri.parse('${AppConfig.baseUrl}/itineraries'),
              headers: headers,
              body: jsonEncode({
                ...item,
                'content': response.body
              })
            );
          } else {
            stillPendingAi.add(item);
          }
        } catch (e) {
          stillPendingAi.add(item);
        }
      }
      await _box.put('pending_ai', jsonEncode(stillPendingAi));
    }
  }
}