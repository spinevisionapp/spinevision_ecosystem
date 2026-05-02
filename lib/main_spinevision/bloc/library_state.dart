import 'package:equatable/equatable.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<BookModel> books;

  const LibraryLoaded(this.books);

  @override
  List<Object> get props => [books];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object> get props => [message];
}
