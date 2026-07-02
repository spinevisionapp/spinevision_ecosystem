import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/app_theme.dart';

class BundleVisionScreen extends StatefulWidget {
  const BundleVisionScreen({super.key});

  @override
  State<BundleVisionScreen> createState() => _BundleVisionScreenState();
}

class _BundleVisionScreenState extends State<BundleVisionScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _suggestion;
  List<BookModel> _inventory = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final repo = context.read<BookRepository>();
    final books = await repo.getBooks();
    setState(() => _inventory = books);
  }

  Future<void> _optimize() async {
    if (_inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory is empty. Scan books first!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await context.read<BookRepository>().optimizeBundle(_inventory);
      setState(() => _suggestion = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Optimization failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBundle() async {
    if (_suggestion == null) return;

    final bundle = BundleModel(
      bundleTitle: _suggestion!['bundle_title'] ?? 'Untitled Bundle',
      bookIds: List<String>.from(_suggestion!['included_book_ids'] ?? []),
      suggestedPrice: (_suggestion!['suggested_price'] as num).toDouble(),
      marketingStrategy: _suggestion!['marketing_strategy'],
      status: 'Active',
    );

    await context.read<BookRepository>().saveBundle(bundle);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bundle saved to VisionHub!')),
    );
    setState(() => _suggestion = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BundleVision: Set Maximizer'),
        backgroundColor: AppTheme.primaryPurple,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.secondaryTeal),
                  SizedBox(height: 16),
                  Text('Gemini is analyzing high-value pairings...'),
                ],
              ),
            )
          : _suggestion == null
              ? _buildEmptyState()
              : _buildSuggestionDetails(),
      floatingActionButton: _suggestion == null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _optimize,
              label: const Text('Optimize ROI'),
              icon: const Icon(Icons.bolt),
              backgroundColor: AppTheme.secondaryTeal,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_motion, size: 80, color: AppTheme.secondaryTeal),
          const SizedBox(height: 20),
          const Text(
            'Maximize your profit with themed bundles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Text(
              'You have ${_inventory.length} books in inventory ready for analysis.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionDetails() {
    final roi = _suggestion!['roi_improvement_percent'] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            color: AppTheme.primaryPurple.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '+$roi% ROI Boost',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _suggestion!['bundle_title'] ?? 'Themed Bundle',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Target Audience: ${_suggestion!['target_audience']}'),
                  const Divider(height: 32),
                  const Text('Marketing Strategy:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_suggestion!['marketing_strategy'] ?? ''),
                  const SizedBox(height: 20),
                  Text(
                    'Suggested Price: \$${(_suggestion!['suggested_price'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveBundle,
              icon: const Icon(Icons.check),
              label: const Text('Save & List Bundle'),
            ),
          ),
        ],
      ),
    );
  }
}
