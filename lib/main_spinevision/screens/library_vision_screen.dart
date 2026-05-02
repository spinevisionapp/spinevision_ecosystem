import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/main_spinevision/bloc/library_bloc.dart';
import 'package:spinevision_ecosystem/main_spinevision/bloc/library_event.dart';
import 'package:spinevision_ecosystem/main_spinevision/bloc/library_state.dart';
import 'package:spinevision_ecosystem/main_spinevision/widgets/book_list_item.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class LibraryVisionScreen extends StatefulWidget {
  const LibraryVisionScreen({super.key});

  @override
  State<LibraryVisionScreen> createState() => _LibraryVisionScreenState();
}

class _LibraryVisionScreenState extends State<LibraryVisionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryBloc(
        RepositoryProvider.of<BookRepository>(context),
      )..add(LoadLibrary()),
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          title: const Text('Inventory Library'),
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => context.push('/omni_vision'),
              tooltip: 'Launch OmniVision',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, state) {
                  if (state is LibraryLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  } else if (state is LibraryLoaded) {
                    final filteredBooks = state.books.where((b) {
                      final matchesSearch = b.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                                          b.author.toLowerCase().contains(_searchController.text.toLowerCase());
                      if (_selectedFilter == 'All') return matchesSearch;
                      // Logic for filters like 'Listed', 'Unlisted' could go here
                      return matchesSearch;
                    }).toList();

                    if (filteredBooks.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        return BookListItem(book: filteredBooks[index]);
                      },
                    );
                  } else if (state is LibraryError) {
                    return Center(child: Text(state.message));
                  }
                  return const Center(child: Text('Your library is waiting...'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by title, author, or ISBN...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Listed', 'Unlisted', 'Sets', 'High ROI'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.primaryText)),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.dividerColor)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.alternate.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No books found matching your criteria.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
