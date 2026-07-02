import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';

class SetVisionScreen extends StatefulWidget {
  const SetVisionScreen({super.key});

  @override
  State<SetVisionScreen> createState() => _SetVisionScreenState();
}

class _SetVisionScreenState extends State<SetVisionScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _setData;
  BookModel? _currentBook;

  Future<void> _analyzeBook() async {
    // In a real app, this would come from a scanner. 
    // For this prototype, we use a sample book from inventory.
    setState(() => _isLoading = true);

    try {
      final repository = context.read<BookRepository>();
      final books = await repository.getBooks();
      
      if (books.isEmpty) {
        throw Exception('Scan a book first to analyze its set potential.');
      }

      _currentBook = books.first;
      final result = await repository.analyzeSet(_currentBook!);
      
      if (mounted) {
        setState(() {
          _setData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SetVision Analyzer'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_setData == null) _buildEmptyState() else _buildSetDetails(),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzeBook,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_fix_high, color: Colors.white),
        label: const Text('ANALYZE BOOK', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 100),
          Icon(Icons.collections_bookmark, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('No set analyzed yet.', style: TextStyle(color: Colors.grey, fontSize: 18)),
          SizedBox(height: 10),
          Text('Scan a book to see if it belongs to a series.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSetDetails() {
    final bool isPart = _setData!['is_part_of_set'] ?? false;
    final List<dynamic> missing = _setData!['missing_volumes'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  isPart ? Icons.stars : Icons.info_outline,
                  color: isPart ? Colors.amber : Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  isPart ? 'SET DETECTED' : 'NOT PART OF A SET',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                if (isPart) Text(_setData!['set_name'] ?? 'Unknown Series', style: const TextStyle(fontSize: 16, color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (isPart) ...[
          const Text('SERIES PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 1 - (missing.length / (_setData!['total_volumes_in_set'] ?? 1)),
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
          ),
          const SizedBox(height: 24),
          const Text('MISSING VOLUMES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ...missing.map((v) => ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: Text('Volume $v'),
            trailing: TextButton(onPressed: () {}, child: const Text('FIND ON EBAY')),
          )),
          const SizedBox(height: 24),
          _buildFinancials(),
        ],
      ],
    );
  }

  Widget _buildFinancials() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SET COMPLETION BONUS'),
              Text('${((_setData!['set_completion_value_bonus'] ?? 1.0) * 100 - 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RARITY SCORE'),
              Text('${_setData!['rarity_score']}/10', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
