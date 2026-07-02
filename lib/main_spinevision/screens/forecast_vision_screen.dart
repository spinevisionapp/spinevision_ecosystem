import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:provider/provider.dart';

class ForecastVisionScreen extends StatelessWidget {
  const ForecastVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    const String currentTier = 'Enterprise';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ForecastVision'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: GatedFeature(
        currentTier: currentTier,
        requiredTier: 'Enterprise',
        featureName: 'ForecastVision',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildForecastHeader(),
              const SizedBox(height: 24),
              _buildSentimentCard(),
              const SizedBox(height: 24),
              const Text('SEASONAL TRENDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              StreamBuilder<List<ForecastModel>>(
                stream: firestore.getForecastsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final forecasts = snapshot.data ?? [];
                  if (forecasts.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: forecasts.length,
                    itemBuilder: (context, index) {
                      final forecast = forecasts[index];
                      return _buildForecastTile(forecast);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MARKET PROJECTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        SizedBox(height: 4),
        Text('Q3 2026 Outlook', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
      ],
    );
  }

  Widget _buildSentimentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI MARKET SENTIMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                SizedBox(height: 4),
                Text('Overall market is BULLISH. Signed First Editions are expected to appreciate by 12% over the next quarter.', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      child: const Column(
        children: [
          Icon(Icons.timeline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No forecast data available for this cycle.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildForecastTile(ForecastModel forecast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(forecast.category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Demand: ${forecast.seasonalDemand}', style: const TextStyle(fontSize: 12)),
        trailing: Text('\$${forecast.projectedMarketValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
