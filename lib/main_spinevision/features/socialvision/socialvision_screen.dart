import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class SocialVisionScreen extends StatefulWidget {
  const SocialVisionScreen({super.key});

  @override
  State<SocialVisionScreen> createState() => _SocialVisionScreenState();
}

class _SocialVisionScreenState extends State<SocialVisionScreen> {
  final List<String> _platforms = ['Instagram', 'TikTok', 'Facebook'];
  final Map<String, bool> _selectedPlatforms = {'Instagram': true, 'TikTok': false, 'Facebook': true};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SocialVision'),
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
            const Text('Automated Marketing', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Text('Generate AI-powered content for your social media.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 24),
            const Text('Target Platforms', style: AppTextStyles.titleMedium),
            Wrap(
              spacing: 8,
              children: _platforms.map((p) => FilterChip(
                label: Text(p),
                selected: _selectedPlatforms[p]!,
                onSelected: (val) => setState(() => _selectedPlatforms[p] = val),
              )).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Post Generator', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe your post (e.g., "Success story about a rare find")',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate with Gemini'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Scheduled Posts', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildScheduledPost(
              'ROI Tips: Why First Editions Matter',
              'Scheduled for Tomorrow, 10:00 AM',
              ['Instagram', 'Facebook'],
            ),
            _buildScheduledPost(
              'BOLO Alert: Vintage Sci-Fi',
              'Scheduled for Friday, 2:00 PM',
              ['TikTok'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledPost(String title, String time, List<String> platforms) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time),
            const SizedBox(height: 4),
            Row(
              children: platforms.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(_getPlatformIcon(p), size: 16, color: AppColors.secondary),
              )).toList(),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () {},
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Instagram': return Icons.camera_alt;
      case 'TikTok': return Icons.music_note;
      case 'Facebook': return Icons.facebook;
      default: return Icons.share;
    }
  }
}
