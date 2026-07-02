import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class PriceVisionScreen extends StatefulWidget {
  const PriceVisionScreen({super.key});

  @override
  State<PriceVisionScreen> createState() => _PriceVisionScreenState();
}

class _PriceVisionScreenState extends State<PriceVisionScreen> {
  bool _isLoading = true;
  List<dynamic> _alerts = [];
  String _marketSentiment = 'Analyzing market...';

  @override
  void initState() {
    super.initState();
    _loadRepricingData();
  }

  Future<void> _loadRepricingData() async {
    try {
      final repository = context.read<BookRepository>();
      final result = await repository.repriceInventory();
      
      if (mounted) {
        setState(() {
          _alerts = result['alerts'] ?? [];
          _marketSentiment = result['market_sentiment'] ?? 'Neutral';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PriceVision Repricer'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSentimentCard(),
              Expanded(
                child: _alerts.isEmpty 
                  ? _buildEmptyState()
                  : _buildAlertList(),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _isLoading = true);
          _loadRepricingData();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('SCAN MARKET', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSentimentCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MARKET SENTIMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(_marketSentiment, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('All prices are optimized!', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAlertList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        final bool isIncrease = alert['action'] == 'INCREASE';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(
              isIncrease ? Icons.trending_up : Icons.trending_down,
              color: isIncrease ? Colors.green : Colors.red,
            ),
            title: Text(alert['reason'] ?? 'Price Adjustment', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Market Delta: ${alert['market_delta']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncrease ? '+' : '-'}${alert['percentage']}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isIncrease ? Colors.green : Colors.red,
                    fontSize: 16
                  ),
                ),
                const Text('SUGGESTED', style: TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
