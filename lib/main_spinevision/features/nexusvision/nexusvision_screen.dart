import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class NexusVisionScreen extends StatelessWidget {
  const NexusVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NexusVision'),
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
            const Text('Connected Services', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Text('Manage your external marketplace integrations.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            _buildServiceTile(
              context,
              name: 'Amazon Professional',
              icon: Icons.shopping_bag,
              status: 'Connected',
              lastSync: '10 mins ago',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildServiceTile(
              context,
              name: 'eBay Motors & Collectibles',
              icon: Icons.storefront,
              status: 'Connected',
              lastSync: '2 hours ago',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildServiceTile(
              context,
              name: 'Shopify Store',
              icon: Icons.language,
              status: 'Not Connected',
              lastSync: '-',
              color: Colors.green,
            ),
            const SizedBox(height: 32),
            const Text('Sync Controls', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSyncRow('Inventory Sync', true),
                    const Divider(),
                    _buildSyncRow('Price Matching', true),
                    const Divider(),
                    _buildSyncRow('Order Importing', false),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.sync),
                      label: const Text('Force Global Sync'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context, {
    required String name,
    required IconData icon,
    required String status,
    required String lastSync,
    required Color color,
  }) {
    final isConnected = status == 'Connected';

    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: AppTextStyles.titleMedium),
        subtitle: Text('Last Sync: $lastSync'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              status,
              style: TextStyle(
                color: isConnected ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(isConnected ? 'Settings' : 'Connect', style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncRow(String title, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyLarge),
        Switch(
          value: value,
          onChanged: (val) {},
          activeThumbColor: AppColors.secondary,
        ),
      ],
    );
  }
}
