import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class PromoVisionScreen extends StatelessWidget {
  const PromoVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromoVision'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentTierCard(),
            const SizedBox(height: 24),
            Text('Membership Tiers', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildTierOption(
              context,
              tier: 'Hobbyist (Free)',
              price: '$0/mo',
              features: ['ThriftVision', 'Basic Library', 'Manual Pricing'],
              color: Colors.grey,
              isCurrent: true,
            ),
            const SizedBox(height: 12),
            _buildTierOption(
              context,
              tier: 'Pro Reseller',
              price: '$49/mo',
              features: ['ShelfVision', 'NexusVision Sync', 'BOLO Alerts', 'VisionLocate'],
              color: AppColors.primary,
              isCurrent: false,
            ),
            const SizedBox(height: 12),
            _buildTierOption(
              context,
              tier: 'Enterprise Visionary',
              price: '$99/mo',
              features: ['SpatialVision AR', 'ProfitVision Analytics', 'ChatVision AI', 'FBA Box Builder'],
              color: AppColors.tertiary,
              isCurrent: false,
            ),
            const SizedBox(height: 32),
            Text('Milestone Rewards', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildMilestoneProgress('100 Books Scanned', 0.75, 'Get 1 day of Pro Access'),
            _buildMilestoneProgress('First $500 Profit', 0.20, 'Exclusive "Early Bird" Badge'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTierCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.purpleRose,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT TIER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const Text('Hobbyist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
          const SizedBox(height: 8),
          const Text('Unlock Pro features to 5x your sourcing speed!', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            child: const Text('View Upgrade Options'),
          ),
        ],
      ),
    );
  }

  Widget _buildTierOption(
    BuildContext context, {
    required String tier,
    required String price,
    required List<String> features,
    required Color color,
    required bool isCurrent,
  }) {
    return Card(
      elevation: isCurrent ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tier, style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(f),
                ],
              ),
            )),
            const SizedBox(height: 16),
            if (!isCurrent)
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Upgrade Now'),
              )
            else
              const Center(child: Text('Your Active Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneProgress(String title, double progress, String reward) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.lightGrey,
              color: AppColors.secondary,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text('Reward: $reward', style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
