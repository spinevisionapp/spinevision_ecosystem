
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  bool _isLoading = true;
  int _currentScans = 0;
  int _targetScans = 50;
  String _currentTier = 'Hobbyist';

  @override
  void initState() {
    super.initState();
    _loadPromotionData();
  }

  Future<void> _loadPromotionData() async {
    try {
      final repository = context.read<BookRepository>();
      final stats = await repository.getUserStats();
      final milestones = await repository.getMilestones();
      
      if (mounted) {
        setState(() {
          _currentScans = (stats['scans_this_month'] as num?)?.toInt() ?? 0;
          _currentTier = repository.currentTier;
          
          if (_currentTier == 'Hobbyist') {
            _targetScans = (milestones['SCANS_FOR_PRO_TRIAL'] as num?)?.toInt() ?? 50;
          } else if (_currentTier == 'Pro') {
            _targetScans = (milestones['SCANS_FOR_ENTERPRISE_TRIAL'] as num?)?.toInt() ?? 500;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_currentScans / _targetScans).clamp(0.0, 1.0);
    final int remaining = (_targetScans - _currentScans).clamp(0, _targetScans);
    final String nextTier = _currentTier == 'Hobbyist' ? 'Pro' : 'Enterprise';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Next Reward'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 100),
                const SizedBox(height: 20),
                Text(
                  progress >= 1.0 ? "You've Unlocked It!" : "You're Almost There!",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  progress >= 1.0 
                    ? "Congratulations! You've qualified for a $nextTier trial."
                    : 'Scan $remaining more books to unlock a free trial of SpineVision $nextTier.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 30),
                _buildProgressBar(progress),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: progress >= 1.0 ? () async {
                    try {
                      final promoKey = _currentTier == 'Hobbyist' ? 'Pro_Trial' : 'Enterprise_Trial';
                      await context.read<BookRepository>().activatePromotion(promoKey);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Free Trial Activated! Enjoy your new features.'), backgroundColor: AppColors.success),
                        );
                        _loadPromotionData(); // Refresh local state
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to activate trial: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    progress >= 1.0 ? 'Activate Free Trial' : 'Keep Scanning', 
                    style: const TextStyle(fontSize: 16)
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
        ),
        const SizedBox(height: 10),
        Text(
          '${(progress * 100).toInt()}% Complete',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
