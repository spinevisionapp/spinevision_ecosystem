import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class BundleVisionScreen extends StatefulWidget {
  const BundleVisionScreen({super.key});

  @override
  State<BundleVisionScreen> createState() => _BundleVisionScreenState();
}

class _BundleVisionScreenState extends State<BundleVisionScreen> {
  final List<BookModel> _selectedBooks = [];
  bool _isOptimizing = false;
  Map<String, dynamic>? _bundleAdvice;

  void _addFromInventory(BookModel book) {
    if (_selectedBooks.any((b) => b.isbn == book.isbn)) return;
    setState(() {
      _selectedBooks.add(book);
      _bundleAdvice = null; // Reset advice when selection changes
    });
  }

  void _removeBook(int index) {
    setState(() {
      _selectedBooks.removeAt(index);
      _bundleAdvice = null;
    });
  }

  Future<void> _runAIAutoBundle() async {
    setState(() => _isOptimizing = true);
    
    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final inventory = await repository.getBooks();
      
      // If none selected, let AI pick from full inventory
      // If some selected, let AI optimize that specific bundle
      final result = await repository.optimizeBundle(_selectedBooks.isEmpty ? inventory : _selectedBooks);
      
      if (mounted) {
        if (_selectedBooks.isEmpty && result['included_book_ids'] != null) {
          final List<dynamic> ids = result['included_book_ids'];
          for (var id in ids) {
             final book = inventory.firstWhere((b) => b.id == id || b.isbn == id, orElse: () => inventory.first);
             _addFromInventory(book);
          }
        }

        setState(() {
          _isOptimizing = false;
          _bundleAdvice = result;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('BundleVision'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isOptimizing ? null : _runAIAutoBundle, 
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Auto-Bundle',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (_bundleAdvice != null) _buildAdviceCard(),
          Expanded(
            child: _selectedBooks.isEmpty 
              ? _buildEmptyState() 
              : _buildSelectedList(),
          ),
          _buildActionPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bundle Maximizer', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('Combine items to increase AOV and clear slow inventory.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(child: Text(_bundleAdvice?['bundle_title'] ?? 'Optimized Bundle', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary))),
            ],
          ),
          const SizedBox(height: 12),
          Text('Suggested Price: \$${_bundleAdvice?['suggested_price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_bundleAdvice?['marketing_strategy'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Select 2-5 books or let AI suggest a set.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showInventoryPicker,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('MANUAL SELECTION'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedBooks.length,
      itemBuilder: (context, index) {
        final book = _selectedBooks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.book, color: AppColors.primary),
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.author),
            trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => _removeBook(index)),
          ),
        );
      },
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          if (_selectedBooks.isNotEmpty)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() { _selectedBooks.clear(); _bundleAdvice = null; }),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('CLEAR'),
              ),
            ),
          if (_selectedBooks.isNotEmpty) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedBooks.length < 2 ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: const Text('CREATE BUNDLE LISTING'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInventoryPicker() async {
    final repository = RepositoryProvider.of<BookRepository>(context);
    final inventory = await repository.getBooks();
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inventory Hub', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: inventory.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.book, color: AppColors.primary),
                    title: Text(inventory[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () {
                      _addFromInventory(inventory[i]);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
