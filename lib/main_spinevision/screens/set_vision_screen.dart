import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class SetVisionScreen extends StatefulWidget {
  const SetVisionScreen({super.key});

  @override
  State<SetVisionScreen> createState() => _SetVisionScreenState();
}

class _SetVisionScreenState extends State<SetVisionScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _activeSets = [
    {
      'name': 'The Lord of the Rings',
      'total': 3,
      'found': 1,
      'items': ['The Fellowship of the Ring'],
      'missing': ['The Two Towers', 'The Return of the King'],
      'bonus': 1.5,
    },
    {
      'name': 'Harry Potter (Hardcover)',
      'total': 7,
      'found': 4,
      'items': ['Book 1', 'Book 2', 'Book 3', 'Book 5'],
      'missing': ['Book 4', 'Book 6', 'Book 7'],
      'bonus': 2.0,
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    // In a real app, we'd fetch this from Firestore
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SetVision'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildActiveSetsList(),
                const SizedBox(height: 32),
                _buildSourcingAlerts(),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('TRACK NEW SERIES', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Series Tracking', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('Complete your sets to unlock 1.5x - 3x ROI bonuses.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText)),
      ],
    );
  }

  Widget _buildActiveSetsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeSets.length,
      itemBuilder: (context, index) {
        final set = _activeSets[index];
        final double progress = set['found'] / set['total'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(set['name'], style: AppTextStyles.titleLarge),
            subtitle: Text('Bonus Multiplier: ${set['bonus']}x', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.dividerColor,
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
                Text('${set['found']}/${set['total']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MISSING VOLUMES:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (set['missing'] as List<String>).map((m) => Chip(
                        label: Text(m, style: const TextStyle(fontSize: 10)),
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {}, 
                      icon: const Icon(Icons.search, size: 16), 
                      label: const Text('AUTO-SEARCH MARKETPLACES'),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourcingAlerts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text('Smart AR Sourcing', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'OmniVision will now highlight these missing volumes in spatial mode with a gold glow.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
