import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/local_db_service.dart';
import 'services/notification_service.dart';
import 'screens/app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notification service
  await NotificationService().init();

  runApp(const TaskMateApp());
}

class TaskMateApp extends StatelessWidget {
  const TaskMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (singletons)
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocalDbService>(create: (_) => LocalDbService()),
        Provider<NotificationService>(create: (_) => NotificationService()),

        // Theme
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Auth — depends on AuthService
        ChangeNotifierProxyProvider<AuthService, app_auth.AuthProvider>(
          create: (ctx) => app_auth.AuthProvider(ctx.read<AuthService>()),
          update:
              (ctx, authSvc, prev) => prev ?? app_auth.AuthProvider(authSvc),
        ),

        // Tasks — depends on LocalDb, Firestore, Notifications
        ChangeNotifierProxyProvider3<
          LocalDbService,
          FirestoreService,
          NotificationService,
          TaskProvider
        >(
          create:
              (ctx) => TaskProvider(
                ctx.read<LocalDbService>(),
                ctx.read<FirestoreService>(),
                ctx.read<NotificationService>(),
              ),
          update:
              (ctx, localDb, firestore, notif, prev) =>
                  prev ?? TaskProvider(localDb, firestore, notif),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) {
          return MaterialApp(
            title: 'TaskMate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProv.themeMode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}
