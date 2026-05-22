# lakbai_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



config.dart
// frontend/lib/config.dart

class AppConfig {
  // Centralized base URL configuration
  // Whenever you change networks, change ONLY this single string!
  static const String baseUrl = 'http://10.0.26.4:3000/api';--change IP if usign local host
}