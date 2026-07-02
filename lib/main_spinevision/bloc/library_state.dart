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

  const LibraryLoaded(this.books);
  final List<BookModel> books;

  @override
  List<Object> get props => [books];
}

class LibraryError extends LibraryState {

  const LibraryError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
