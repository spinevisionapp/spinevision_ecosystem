import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class AmazonVisionDashboard extends StatelessWidget {
  const AmazonVisionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AmazonVision Command'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.purpleRose,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarketOverview(),
            _buildQuickActions(context),
            _buildSectionHeader('FBA LOGISTICS & ALERTS'),
            _buildLogisticsCard(context),
            _buildUngatingAlerts(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: AppColors.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AMAZON MARKET SENTIMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkGrey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.success, size: 28),
              SizedBox(width: 12),
              Text('BULLISH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryText)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('High velocity detected in Sci-Fi and Rare Technical manuals. 6-month demand up 14%.', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
          const SizedBox(height: 20),
          _buildFakeKeepaGraph(),
        ],
      ),
    );
  }

  Widget _buildFakeKeepaGraph() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 8, left: 12,
            child: Text('6-MO SALES RANK (AVG)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Center(
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: SparklinePainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _actionButton(Icons.add_photo_alternate, 'LIST FBA', () => context.push('/listing')),
          const SizedBox(width: 16),
          _actionButton(Icons.inventory, 'BOX BUILDER', () => context.push('/fba_box_builder')),
          const SizedBox(width: 16),
          _actionButton(Icons.barcode_reader, 'SCAN PRO', () => context.push('/pro-scan')),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGrey, letterSpacing: 1)),
    );
  }

  Widget _buildLogisticsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVE SHIPMENT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(Icons.local_shipping, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text('FBA_BOX_004', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Row(
            children: [
              Text('32.4 / 45.0 LBS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Spacer(),
              Text('72% FULL', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: 0.72, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.white), minHeight: 6),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/fba_box_builder'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 44)),
            child: const Text('OPEN BOX BUILDER'),
          ),
        ],
      ),
    );
  }

  Widget _buildUngatingAlerts() {
    return Column(
      children: [
        _ungatingTile('Wizards of the Coast', 'RESTRICTED', 'High probability of auto-ungating based on account health.'),
        _ungatingTile('Penguin Random House', 'UNLOCKED', 'Tier 1 whitelist active for your account.'),
      ],
    );
  }

  Widget _ungatingTile(String brand, String status, String advice) {
    final bool restricted = status == 'RESTRICTED';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (restricted ? AppColors.warning : AppColors.success).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(restricted ? Icons.lock_outline : Icons.lock_open, color: restricted ? AppColors.warning : AppColors.success, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(brand, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: restricted ? AppColors.warning : AppColors.success)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(advice, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.9);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
    
    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.primary.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
