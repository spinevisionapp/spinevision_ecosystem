import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class ReviewVisionScreen extends StatefulWidget {
  final List<BookModel> scannedBooks;
  final String batchName;

  const ReviewVisionScreen({
    super.key,
    required this.scannedBooks,
    this.batchName = 'New Batch Scan',
  });

  @override
  State<ReviewVisionScreen> createState() => _ReviewVisionScreenState();
}

class _ReviewVisionScreenState extends State<ReviewVisionScreen> {
  late List<BookModel> _books;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _books = List.from(widget.scannedBooks);
    // By default, select all for import
    _selectedIds.addAll(_books.map((b) => b.id ?? ''));
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _onImport() {
    final booksToImport = _books.where((b) => _selectedIds.contains(b.id ?? '')).toList();

    final totalValue = booksToImport.fold<double>(0, (sum, b) => sum + ((b.listingDetails?['suggestedListPrice'] as num?)?.toDouble() ?? 0.0));

    final repository = RepositoryProvider.of<BookRepository>(context);
    repository.saveBooks(booksToImport);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported ${booksToImport.length} items. Total value: \$${totalValue.toStringAsFixed(2)}'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalPotentialValue = _books
        .where((b) => _selectedIds.contains(b.id ?? ''))
        .fold<double>(0, (sum, b) => sum + ((b.listingDetails?['suggestedListPrice'] as num?)?.toDouble() ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchName),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty ? null : _onImport,
            child: Text(
              'IMPORT',
              style: TextStyle(
                color: _selectedIds.isEmpty ? Colors.white54 : Colors.white, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBatchSummaryCard(totalPotentialValue),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedIds.length} of ${_books.length} items selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _books.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_books.map((b) => b.id ?? ''));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == _books.length ? 'Deselect All' : 'Select All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                final isSelected = _selectedIds.contains(book.id ?? '');

                return GestureDetector(
                  onTap: () => _toggleSelection(book.id ?? ''),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryPurple : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                child: Container(
                                  color: Colors.grey.shade200,
                                  child: book.coverImageUrl != null
                                      ? Image.network(book.coverImageUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.book, size: 64, color: Colors.grey),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${(book.listingDetails?['suggestedListPrice'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primaryPurple,
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchSummaryCard(double totalValue) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryTeal.withValues(alpha: 0.1), AppColors.primaryPurple.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESTIMATED BATCH VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 4),
              Icon(Icons.auto_graph, color: AppColors.primaryTeal),
            ],
          ),
          const Spacer(),
          Text(
            '\$${totalValue.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
          ),
        ],
      ),
    );
  }
}
