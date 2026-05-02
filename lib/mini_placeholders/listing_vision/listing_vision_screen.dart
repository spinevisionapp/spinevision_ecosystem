import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:go_router/go_router.dart';

class ListingVisionScreen extends StatefulWidget {
  final BookModel? initialBook;

  const ListingVisionScreen({super.key, this.initialBook});

  @override
  State<ListingVisionScreen> createState() => _ListingVisionScreenState();
}

class _ListingVisionScreenState extends State<ListingVisionScreen> {
  late BookModel? _selectedBook;
  bool _isGenerating = false;
  String _generatedDescription = '';
  double _suggestedPrice = 0.0;
  
  bool _isFBAMode = false;
  final Map<String, bool> _selectedPlatforms = {
    'eBay': true,
    'Etsy': false,
    'FB Marketplace': false,
    'Amazon FBM': false,
    'Mercari': false,
  };

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBook;
  }

  Future<void> _onGenerateListing() async {
    if (_selectedBook == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final platform = _isFBAMode ? 'Amazon FBA' : 'eBay'; 
      
      final listing = await repository.generateListing(_selectedBook!, platform);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _suggestedPrice = (listing['suggested_price'] as num?)?.toDouble() ?? 0.0;
          _generatedDescription = listing['description'] as String? ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatedDescription = 'Error generating listing: $e';
        });
      }
    }
  }

  void _onPublish() {
    final activeChannels = _isFBAMode 
        ? ['Amazon FBA'] 
        : _selectedPlatforms.entries.where((e) => e.value).map((e) => e.key).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Publishing to: ${activeChannels.join(", ")}...'),
        backgroundColor: AppColors.secondary,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/vision_hub');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<BookRepository>(context);
    final tier = repository.currentTier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ListingVision'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          GatedFeature(
            currentTier: tier,
            requiredTier: 'Enterprise',
            featureName: 'FBA Box Builder',
            child: IconButton(
              onPressed: () => context.push('/fba_box_builder'),
              icon: const Icon(Icons.inventory_2),
              tooltip: 'FBA Logistics',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.primary.withValues(alpha: 0.02)],
          ),
        ),
        child: _selectedBook == null 
          ? _buildEmptyState() 
          : _buildListingEditor(tier),
      ),
      bottomNavigationBar: _selectedBook != null && _generatedDescription.isNotEmpty
        ? _buildBottomBar()
        : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sell_outlined, size: 80, color: AppColors.alternate.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Select an item from your hub to list', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/vision_hub'), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('GO TO HUB'),
          ),
        ],
      ),
    );
  }

  Widget _buildListingEditor(String tier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemCard(),
          const SizedBox(height: 24),
          GatedFeature(
            currentTier: tier,
            requiredTier: 'Pro',
            featureName: 'Multi-Platform and FBA Listing',
            child: _buildModeToggle(),
          ),
          const SizedBox(height: 20),
          if (!_isFBAMode) _buildPlatformMultiSelect(),
          if (_isFBAMode) _buildFBAInfo(),
          const SizedBox(height: 32),
          _buildGenerationArea(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton("Multi-Platform", !_isFBAMode, () => setState(() => _isFBAMode = false)),
          ),
          Expanded(
            child: _toggleButton("Amazon FBA", _isFBAMode, () => setState(() => _isFBAMode = true)),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.primaryText, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildPlatformMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Target Channels', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _selectedPlatforms.keys.map((p) {
            return FilterChip(
              label: Text(p),
              selected: _selectedPlatforms[p]!,
              onSelected: (val) => setState(() => _selectedPlatforms[p] = val),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(color: _selectedPlatforms[p]! ? AppColors.primary : AppColors.secondaryText),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFBAInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: AppColors.warning)
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(child: Text('Amazon FBA Mode will handle inbound logistics and prime-eligible pricing.', style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildGenerationArea() {
    if (_isGenerating) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_generatedDescription.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _onGenerateListing,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_isFBAMode ? 'GENERATE FBA LISTING' : 'GENERATE FOR ALL CHANNELS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }
    return _buildAIResultPreview();
  }

  Widget _buildItemCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
      ),
      child: Row(
        children: [
          _selectedBook!.coverImageUrl != null
            ? Image.network(_selectedBook!.coverImageUrl!, width: 60, height: 80, fit: BoxFit.cover)
            : Container(width: 60, height: 80, color: AppColors.secondaryBackground, child: const Icon(Icons.book, color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedBook!.title, style: AppTextStyles.titleMedium),
                Text(_selectedBook!.author, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars, color: AppColors.success),
            const SizedBox(width: 8),
            Text('Suggested Price: \$${_suggestedPrice.toStringAsFixed(2)}', 
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerColor),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 16, color: AppColors.secondaryText),
                  const SizedBox(width: 8),
                  Text('AI GENERATED DESCRIPTION', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondaryText)),
                ],
              ),
              const SizedBox(height: 12),
              Text(_generatedDescription, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _onPublish,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54)),
          child: Text(_isFBAMode ? 'SEND TO FBA SHIPMENT' : 'PUBLISH TO ALL CHANNELS'),
        ),
      ),
    );
  }
}
