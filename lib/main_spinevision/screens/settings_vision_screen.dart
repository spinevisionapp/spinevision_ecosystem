import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';

class SettingsVisionScreen extends StatefulWidget {
  const SettingsVisionScreen({super.key});

  @override
  State<SettingsVisionScreen> createState() => _SettingsVisionScreenState();
}

class _SettingsVisionScreenState extends State<SettingsVisionScreen> {
  // Mock Settings State
  double _minProfit = 15.0;
  int _maxSalesRank = 500000;
  bool _ebayConnected = true;
  bool _amazonConnected = false;
  bool _isVoiceEnabled = true;

  void _openPaywall() => context.push('/paywall');

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<BookRepository>(context);
    final currentTier = repository.currentTier;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Command Center'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(currentTier),
            const SizedBox(height: 32),
            _buildSectionHeader('SOURCING STRATEGY', Icons.insights),
            _buildStrategySection(currentTier),
            const SizedBox(height: 32),
            _buildSectionHeader('API INTEGRATIONS', Icons.sync),
            _buildIntegrationMatrix(),
            const SizedBox(height: 32),
            _buildSectionHeader('PREFERENCES', Icons.settings),
            _buildPreferenceHub(),
            const SizedBox(height: 40),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String tier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Power User', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    tier.toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openPaywall, 
            icon: const Icon(Icons.upgrade, color: Colors.white),
            tooltip: 'Change Plan',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStrategySection(String tier) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildThresholdSlider(
              'Minimum Net Profit', 
              '\$${_minProfit.toInt()}', 
              _minProfit / 100, 
              (v) => setState(() => _minProfit = v * 100)
            ),
            const Divider(height: 32),
            GatedFeature(
              currentTier: tier,
              requiredTier: 'Pro',
              featureName: 'Max Sales Rank Filter',
              child: _buildThresholdSlider(
                'Maximum Sales Rank', 
                '${(_maxSalesRank / 1000).toInt()}k', 
                _maxSalesRank / 2000000, 
                (v) => setState(() => _maxSalesRank = (v * 2000000).toInt())
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSlider(String label, String value, double progress, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyLarge),
            Text(value, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: progress, 
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.dividerColor,
        ),
      ],
    );
  }

  Widget _buildIntegrationMatrix() {
    return Row(
      children: [
        _buildIntegrationTile('eBay', Icons.storefront, _ebayConnected),
        const SizedBox(width: 12),
        _buildIntegrationTile('Amazon', Icons.shopping_bag, _amazonConnected),
        const SizedBox(width: 12),
        _buildIntegrationTile('Discogs', Icons.album, false),
      ],
    );
  }

  Widget _buildIntegrationTile(String name, IconData icon, bool connected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: connected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: connected ? AppColors.secondary : AppColors.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: connected ? AppColors.secondary : Colors.grey),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(connected ? 'SYNCED' : 'OFFLINE', style: TextStyle(color: connected ? AppColors.secondary : Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceHub() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('AI Voice Feedback'),
            subtitle: const Text('Hands-free buy/skip announcements'),
            value: _isVoiceEnabled, 
            onChanged: (v) => setState(() => _isVoiceEnabled = v),
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Currency Display'),
            trailing: const Text('USD (\$)', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Notification Triggers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text('Sign Out of SpineVision', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
