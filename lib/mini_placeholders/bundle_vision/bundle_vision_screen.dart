import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
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
  double _bundlePrice = 0.0;
Future<void> _onAddFromLibrary() async {
  final repository = RepositoryProvider.of<BookRepository>(context);
  final allBooks = await repository.getBooks();

  if (!mounted) return;

  // Simple picker simulation - pick a book not already in the bundle
  final available = allBooks.where((b) => !_selectedBooks.any((sb) => sb.id == b.id)).toList();

  if (available.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(        const SnackBar(content: Text('No more books available in Library.')),
      );
      return;
    }

    setState(() {
      _selectedBooks.add(available.first);
      _bundleAdvice = null; // Reset advice when selection changes
    });
  }

  Future<void> _onOptimizeBundle() async {
    if (_selectedBooks.isEmpty) return;

    setState(() {
      _isOptimizing = true;
      _bundleAdvice = null;
    });

    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final advice = await repository.optimizeBundle(_selectedBooks);

      if (mounted) {
        setState(() {
          _isOptimizing = false;
          _bundleAdvice = advice;
          _bundlePrice = (advice['suggested_price'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOptimizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Optimization failed: $e')),
        );
      }
    }
  }

  void _onSaveBundle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bundle strategy saved to listings queue.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BundleVision'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildBundleHeader(),
          Expanded(
            child: _selectedBooks.isEmpty 
              ? _buildEmptyState() 
              : _buildBookList(),
          ),
          if (_bundleAdvice != null) _buildAdvicePanel(),
          _buildActionPanel(),
        ],
      ),
    );
  }

  Widget _buildBundleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_motion, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI BUNDLE CREATOR',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGrey, letterSpacing: 1.2),
              ),
              Text(
                '${_selectedBooks.length} items in draft', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'Select books to analyze for bundling',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryTeal, Color(0xFF24A092)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton.icon(
        onPressed: _onAddFromLibrary,
        icon: const Icon(Icons.add),
        label: const Text('ADD FROM LIBRARY', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedBooks.length + 1,
      itemBuilder: (context, index) {
        if (index == _selectedBooks.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: Center(child: _buildAddButton()),
          );
        }
        final book = _selectedBooks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 40,
                height: 60,
                color: Colors.grey.shade100,
                child: book.coverImageUrl != null 
                  ? Image.network(book.coverImageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.book, color: Colors.grey),
              ),
            ),
            title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(book.author),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
              onPressed: () {
                setState(() {
                  _selectedBooks.removeAt(index);
                  _bundleAdvice = null;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvicePanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryPurple.withValues(alpha: 0.05), AppColors.primaryTeal.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text('GEMINI BUNDLE STRATEGY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Spacer(),
              Text(
                '\$${_bundlePrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.success),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            _bundleAdvice!['bundle_title'] ?? 'Optimized Bundle',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${_bundleAdvice!['target_audience']}',
            style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.darkGrey),
          ),
          const SizedBox(height: 16),
          Text(
            _bundleAdvice!['marketing_strategy'] ?? '',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${_bundleAdvice!['roi_improvement_percent']}% ROI Improvement',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _selectedBooks.length < 2 || _isOptimizing ? null : _onOptimizeBundle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 54),
                side: const BorderSide(color: AppColors.primaryPurple),
                foregroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isOptimizing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple)) 
                : const Text('OPTIMIZE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: _selectedBooks.isEmpty || _bundleAdvice == null ? null : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                color: _selectedBooks.isEmpty || _bundleAdvice == null ? Colors.grey.shade200 : null,
              ),
              child: ElevatedButton(
                onPressed: _selectedBooks.isEmpty || _bundleAdvice == null ? null : _onSaveBundle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CREATE BUNDLE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
