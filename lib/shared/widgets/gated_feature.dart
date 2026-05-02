
import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:go_router/go_router.dart';

class GatedFeature extends StatelessWidget {
  final String currentTier;
  final String requiredTier;
  final Widget child;
  final String? featureName;

  const GatedFeature({
    super.key,
    required this.currentTier,
    required this.requiredTier,
    required this.child,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    bool isLocked = false;
    if (requiredTier == 'Pro' && currentTier == 'Hobbyist') {
      isLocked = true;
    }
    if (requiredTier == 'Enterprise' && currentTier != 'Enterprise') {
      isLocked = true;
    }

    return Stack(
      children: [
        child,
        if (isLocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 32, color: Colors.amber.shade800),
                      const SizedBox(height: 12),
                      Text(
                        'Upgrade to $requiredTier to unlock${featureName != null ? ' $featureName' : ''}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/upgrade'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('View Upgrade Plans'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
