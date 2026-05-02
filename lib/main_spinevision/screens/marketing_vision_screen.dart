import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class MarketingVisionScreen extends StatefulWidget {
  const MarketingVisionScreen({super.key});

  @override
  State<MarketingVisionScreen> createState() => _MarketingVisionScreenState();
}

class _MarketingVisionScreenState extends State<MarketingVisionScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _weeklySchedule = {};

  @override
  void initState() {
    super.initState();
    _loadSocialContent();
  }

  Future<void> _loadSocialContent() async {
    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      // Simulating the backend AI generation
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _weeklySchedule = {
            'Monday': {'type': 'Success Story', 'content': 'Just found this first edition Tolkien! Sourced for \$2, selling for \$85. ROI is insane! #SpineVision', 'status': 'Draft'},
            'Wednesday': {'type': 'BOLO Alert', 'content': 'Keep an eye out for 1980s computer programming guides. Collector demand is spiking! #ResellerTips', 'status': 'Draft'},
            'Friday': {'type': 'Weekly Tally', 'content': 'Another \$450 in potential profit found this week using OmniVision. Sourcing made easy.', 'status': 'Draft'},
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _approvePost(String day) {
    setState(() {
      _weeklySchedule[day]['status'] = 'Approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$day post approved and scheduled!'), backgroundColor: AppColors.secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketingVision'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPostList(),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('RE-GENERATE WEEK', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Social Content Planner', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('AI-generated posts tailored to your recent high-ROI finds.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText)),
      ],
    );
  }

  Widget _buildPostList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _weeklySchedule.length,
      itemBuilder: (context, index) {
        final day = _weeklySchedule.keys.elementAt(index);
        final post = _weeklySchedule[day];
        final isApproved = post['status'] == 'Approved';

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey, fontSize: 10)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post['type'], 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isApproved ? AppColors.secondary : AppColors.primary)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(post['content'], style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.instagram, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Icon(Icons.facebook, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Icon(Icons.movie_creation_outlined, size: 18, color: Colors.grey),
                    const Spacer(),
                    if (!isApproved)
                      ElevatedButton(
                        onPressed: () => _approvePost(day),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20)),
                        child: const Text('APPROVE & POST'),
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.secondary, size: 16),
                          SizedBox(width: 8),
                          Text('SCHEDULED', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
