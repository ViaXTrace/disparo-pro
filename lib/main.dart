import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/background/dispatch_worker.dart';
import 'core/database/app_database.dart';
import 'core/notifications/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return DispatchWorker.run(task, inputData);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize background worker
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Initialize notifications
  await NotificationService.instance.initialize();

  // Initialize database
  final db = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const DisparoProApp(),
    ),
  );
}
