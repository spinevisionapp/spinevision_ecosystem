import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class DashVisionScreen extends StatelessWidget {
  const DashVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DashVision'),
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
            Text('Overview', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            _buildQuickStats(),
            const SizedBox(height: 24),
            Text('Navigation', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildNavigationGrid(context),
            const SizedBox(height: 24),
            Text('Recent BOLO Alerts', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildBoloList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Profit',
            value: '$1,245.50',
            icon: Icons.payments,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Total Listings',
            value: '342',
            icon: Icons.inventory_2,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    final modules = [
      {'title': 'OmniVision', 'icon': Icons.camera_alt, 'color': AppColors.primary},
      {'title': 'OperateVision', 'icon': Icons.business_center, 'color': AppColors.secondary},
      {'title': 'NexusVision', 'icon': Icons.hub, 'color': AppColors.tertiary},
      {'title': 'SocialVision', 'icon': Icons.share, 'color': AppColors.accent1},
      {'title': 'AssistVision', 'icon': Icons.assistant, 'color': AppColors.info},
      {'title': 'PromoVision', 'icon': Icons.star, 'color': AppColors.warning},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return InkWell(
          onTap: () {
            // Navigation logic would go here
          },
          child: Card(
            elevation: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(module['icon'] as IconData, color: module['color'] as Color, size: 32),
                const SizedBox(height: 8),
                Text(
                  module['title'] as String,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoloList() {
    final bolos = [
      {'title': 'First Edition: The Great Gatsby', 'roi': '450%'},
      {'title': 'Signed Copy: Stephen King - IT', 'roi': '320%'},
      {'title': 'Vintage Textbook: Organic Chemistry', 'roi': '210%'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bolos.length,
      itemBuilder: (context, index) {
        final bolo = bolos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.tertiary,
              child: Icon(Icons.trending_up, color: Colors.white),
            ),
            title: Text(bolo['title']!),
            subtitle: Text('Estimated ROI: ${bolo['roi']}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.titleLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(title, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
