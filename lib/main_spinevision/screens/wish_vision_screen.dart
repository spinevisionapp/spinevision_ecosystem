import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class WishVisionScreen extends StatefulWidget {
  const WishVisionScreen({super.key});

  @override
  State<WishVisionScreen> createState() => _WishVisionScreenState();
}

class _WishVisionScreenState extends State<WishVisionScreen> {
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();

  void _addWish() async {
    if (_isbnController.text.isEmpty) return;
    
    final repository = RepositoryProvider.of<BookRepository>(context);
    final wish = WishModel(
      isbn: _isbnController.text,
      targetProfit: double.tryParse(_profitController.text) ?? 20.0,
    );

    await repository.saveWish(wish);
    _isbnController.clear();
    _profitController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target added to WishVision!'), backgroundColor: AppColors.secondary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<BookRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WishVision Targets'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInputSection(),
          const Divider(height: 1),
          Expanded(child: _buildWishlist(repository)),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add "Golden Snitch" Target', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _isbnController,
                  decoration: InputDecoration(hintText: 'ISBN or Keyword', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _profitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: 'Target \$', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: IconButton(onPressed: _addWish, icon: const Icon(Icons.add, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('OmniVision will pulse gold when these items are detected.', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildWishlist(BookRepository repository) {
    return StreamBuilder<List<WishModel>>(
      stream: repository.getWishlistStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final wishes = snapshot.data ?? [];

        if (wishes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: AppColors.secondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('No active targets.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wishes.length,
          itemBuilder: (context, index) {
            final wish = wishes[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.stars, color: Colors.amber),
                title: Text(wish.isbn, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Min. Profit Target: \$${wish.targetProfit.toStringAsFixed(2)}'),
                trailing: Switch(
                  value: wish.isActive, 
                  onChanged: (v) => repository.saveWish(wish.copyWith(isActive: v)),
                  activeColor: AppColors.secondary,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
