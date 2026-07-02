import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:provider/provider.dart';

class VisionLocateScreen extends StatelessWidget {
  const VisionLocateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    final repository = context.watch<BookRepository>();
    final String currentTier = repository.currentTier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VisionLocate'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: GatedFeature(
        currentTier: currentTier,
        requiredTier: 'Pro',
        featureName: 'VisionLocate',
        child: Column(
          children: [
            _buildLocateHeader(),
            Expanded(
              child: StreamBuilder<List<LocationModel>>(
                stream: firestore.getLocationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final locations = snapshot.data ?? [];
                  if (locations.isEmpty) {
                    return _buildEmptyState();
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return _buildLocationCard(location);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, 
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.route, color: Colors.white),
        label: const Text('GENERATE PICK LIST', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildLocateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WAREHOUSE MAPPING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          SizedBox(height: 4),
          Text('8 Active Shelves', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No locations mapped yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shelves, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text('Shelf ${location.shelfId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Bin ${location.binId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('${location.bookIds.length} items', style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
