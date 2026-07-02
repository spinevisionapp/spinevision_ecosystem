import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/services/api_service.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';

/// A widget that initializes and provides the core ecosystem services
/// and repositories to the entire application.
class VisionProvider extends StatelessWidget {

  const VisionProvider({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(create: (context) => ApiService()),
        RepositoryProvider<FirestoreService>(
          create: (context) => FirestoreService(),
        ),
        RepositoryProvider<BookRepository>(
          create: (context) => BookRepository(
            RepositoryProvider.of<ApiService>(context),
            RepositoryProvider.of<FirestoreService>(context),
          ),
        ),
      ],
      child: child,
    );
  }
}
