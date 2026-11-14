// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/theme/theme_controller.dart';
import 'features/reminder/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();
  final theme = await ThemeController.load();
  await NotificationService.instance.init();
  final reminder = NursingReminderController()..start();
  runApp(YorunohikariApp(theme: theme, reminder: reminder));
}
