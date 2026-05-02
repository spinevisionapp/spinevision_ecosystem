
import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class PromotionScreen extends StatelessWidget {
  const PromotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Next Reward'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 100),
            const SizedBox(height: 20),
            const Text(
              "You're Almost There!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan 10 more books to unlock a free 7-day trial of SpineVision Pro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 30),
            _buildProgressBar(0.8), // Example progress
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // In a real app, this would activate the trial
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Free Trial Activated!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Activate Free Trial', style: TextStyle(fontSize: 16)),
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
