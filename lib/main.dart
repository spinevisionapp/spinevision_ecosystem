import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/blocs/membership/membership_bloc.dart';
import 'package:spinevision_ecosystem/shared/services/api_service.dart';
import 'package:spinevision_ecosystem/shared/services/auth_service.dart';
import 'package:spinevision_ecosystem/shared/services/storage_service.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize RevenueCat for subscription management and entitlement sync
  await _configureRevenueCat();

  final authService = AuthService();
  final apiService = ApiService(authService: authService);
  final storageService = CloudStorageService();
  final firestoreService = FirestoreService();
  final bookRepository = BookRepository(apiService, firestoreService);

  // Auto sign-in for the blueprint
  await authService.signInAnonymously();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: apiService),
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: firestoreService),
        RepositoryProvider.value(value: bookRepository),
      ],
      child: BlocProvider(
        create: (context) => MembershipBloc(authService)..add(MembershipStarted()),
        child: const MaterialApp(
          home: Scaffold(body: Center(child: Text('SpineVision Loaded'))),
        ),
      ),
    ),
  );
}

Future<void> _configureRevenueCat() async {
  // Enable debug logs for development. Set to false for production.
  await Purchases.setLogLevel(LogLevel.debug);

  PurchasesConfiguration configuration;

  if (Platform.isAndroid) {
    // Replace with your actual Android Public SDK Key
    configuration = PurchasesConfiguration("goog_spinevision_android_public_key");
  } else if (Platform.isIOS) {
    // Replace with your actual iOS Public SDK Key
    configuration = PurchasesConfiguration("appl_spinevision_ios_public_key");
  } else {
    // Skip configuration for unsupported platforms
    return;
  }

  await Purchases.configure(configuration);
}