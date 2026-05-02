
import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Unlock Your Full Potential',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose the plan that fits your reselling journey.',
              style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildTierCard(
              tier: 'Pro',
              price: '\$29',
              period: '/ month',
              features: [
                'Batch/Shelf Mode',
                'Custom Tags & Search',
                'Gemini Receipt OCR',
                'AI Copywriting',
                'Profit/ROI Trends',
                'AI Bundle Optimizer',
                'Keepa & Box Builder',
                'Chat Bot Support',
              ],
              buttonText: 'Upgrade to Pro',
              isRecommended: true,
            ),
            const SizedBox(height: 20),
            _buildTierCard(
              tier: 'Enterprise',
              price: '\$99',
              period: '/ month',
              features: [
                'All Pro Features',
                'Live AR Spatial Mode',
                'Bin/Location Mapping (AR)',
                'Projections & Tax Export',
                'Multi-Platform Auto-Sync',
                'AI Strategic Sourcing',
                'High-Value Collector Set Alerts',
                'Automated FBA Inbound',
                'Live Agent Access',
              ],
              buttonText: 'Go Enterprise',
            ),
             const SizedBox(height: 20),
            _buildTierCard(
              tier: 'Hobbyist',
              price: 'Free',
              period: '',
              features: [
                'Single Scan Only',
                'View/Delete items',
                'Manual COGS/Miles',
                'Manual Entry Only',
                'Basic Stats',
                'View Bundles only',
                'ISBN Lookup',
                'Self-Service Support',
              ],
              buttonText: 'Current Plan',
              isCurrent: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String price,
    required String period,
    required List<String> features,
    required String buttonText,
    bool isRecommended = false,
    bool isCurrent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecommended ? AppColors.primaryPurple : Colors.grey.shade200,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: [
          if (isRecommended)
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tier,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              if(period.isNotEmpty)
              Text(
                period,
                style: const TextStyle(fontSize: 16, color: AppColors.darkGrey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
           ElevatedButton(
            onPressed: isCurrent ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecommended ? AppColors.primaryPurple : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
