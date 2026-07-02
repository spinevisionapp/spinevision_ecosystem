import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spinevision_ecosystem/shared/navigation/routes.dart';
import 'package:spinevision_ecosystem/shared/theme/app_theme.dart';
import 'package:spinevision_ecosystem/shared/widgets/vision_provider.dart';

void main() async {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))));
  
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    print('GLOBAL ERROR: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  try {
    await Firebase.initializeApp();
    runApp(const SpineVisionApp());
  } catch (e) {
    print('FIREBASE INIT ERROR: $e');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Init Error: $e')))));
  }
}

class SpineVisionApp extends StatelessWidget {
  const SpineVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VisionProvider(
      child: MaterialApp.router(
        title: 'SpineVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
