// main.dart
import 'package:flutter/material.dart';
import 'app_router.dart'; // contains initializeApp() and appRouter

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await initializeApp();
  runApp(app);
}
