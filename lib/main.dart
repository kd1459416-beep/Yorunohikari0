// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/theme/theme_controller.dart';
import 'features/reminder/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();
  // iOS/macOSはGIDClientIDが必要（Androidはパッケージ名とSHA-1で識別するため無視される）
  await GoogleSignIn.instance.initialize(
    clientId:
        '744624841714-q8n7ng1nqees18unbgmi9i3gcld55mmk.apps.googleusercontent.com',
  );
  final theme = await ThemeController.load();
  await NotificationService.instance.init();
  final reminder = NursingReminderController()..start();
  runApp(YorunohikariApp(theme: theme, reminder: reminder));
}
