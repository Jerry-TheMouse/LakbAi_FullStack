import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert'; // <-- ADDED FOR BASE64 DECODING
import '../providers/destinations_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Luzon', 'Visayas', 'Mindanao'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DestinationsProvider>(context, listen: false).fetchDestinations();
    });
  }

  // --- NEW Helper Function to handle Base64 AND Web URLs perfectly ---
  Widget _buildImage(String rawImageUrl) {
    if (rawImageUrl.isEmpty) {
      return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
    }
    
    // Check if it is a Base64 string from the "Add New" form
    if (rawImageUrl.startsWith('data:image')) {
      try {
        final base64String = rawImageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
      } catch (e) {
        return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
      }
    } 
    // Check if it is a standard web link
    else if (rawImageUrl.startsWith('http')) {
      return Image.network(rawImageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
    } 
    // Fallback: Assume it's a relative path from your older React data
    else {
      return Image.network('http://localhost:3000/$rawImageUrl', fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F4EA), // Light mint background matching your repo
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Explore Destinations', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell, color: Color(0xFF064E3B)), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search spots, beaches, mountains...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF059669)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          
          // 2. Category Pills
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF059669),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 3. Database Results List
          Expanded(
            child: Consumer<DestinationsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }
                
                final filteredDestinations = provider.destinations.where((dest) {
                  if (_selectedCategory == 'All') return true;
                  final location = (dest['location'] ?? dest['region'] ?? '').toString().toLowerCase();
                  return location.contains(_selectedCategory.toLowerCase());
                }).toList();

                if (filteredDestinations.isEmpty) {
                  return const Center(child: Text('No destinations match this category.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  itemCount: filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final dest = filteredDestinations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildRegionCard(context, dest).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(BuildContext context, Map<String, dynamic> dest) {
    final title = dest['name'] ?? dest['title'] ?? 'Unknown Place';
    final location = dest['location'] ?? dest['region'] ?? 'PHILIPPINES';
    final description = dest['description'] ?? 'Explore this beautiful tourist destination.';
    final rawImageUrl = dest['image'] ?? dest['imageUrl'] ?? ''; // Grab the image data

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Image - USING THE NEW HELPER FUNCTION
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _buildImage(rawImageUrl),
          ),
          
          // 2. White Details Box
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(location.toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.push('/details', extra: dest);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFFD1FAE5), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}