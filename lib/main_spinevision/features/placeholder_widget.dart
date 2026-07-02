import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class MiniAppPlaceholder extends StatelessWidget {
  const MiniAppPlaceholder({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('$title Module coming soon', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
