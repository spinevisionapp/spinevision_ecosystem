import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final BookRepository _bookRepository;

  LibraryBloc(this._bookRepository) : super(LibraryInitial()) {
    on<LoadLibrary>((event, emit) async {
      emit(LibraryLoading());
      try {
        final books = await _bookRepository.getBooks();
        emit(LibraryLoaded(books));
      } catch (e) {
        emit(LibraryError(e.toString()));
      }
    });
  }
}
