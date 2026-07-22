import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:spinevision_ecosystem/shared/widgets/feature_gate.dart';

class OmniVisionScreen extends StatefulWidget {
  const OmniVisionScreen({super.key});

  @override
  State<OmniVisionScreen> createState() => _OmniVisionScreenState();
}

class _OmniVisionScreenState extends State<OmniVisionScreen> {
  int _selectedMode = 0; // 0: Thrift, 1: Shelf, 2: Spatial

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera background feel
      appBar: AppBar(
        title: const Text('OmniVision'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.camera_alt, size: 100, color: Colors.white24),
            ),
          ),
          
          // Overlay based on mode
          _buildScanningOverlay(),

          // Mode Selector
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildModeSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    switch (_selectedMode) {
      case 0: // ThriftVision
        return _buildThriftOverlay();
      case 1: // ShelfVision
        return FeatureGate(
          requiredTier: VisionTier.mid,
          lockedPlaceholder: _buildLockedOverlay('ShelfVision (Pro Feature)'),
          child: _buildShelfOverlay(),
        );
      case 2: // SpatialVision
        return FeatureGate(
          requiredTier: VisionTier.top,
          lockedPlaceholder: _buildLockedOverlay('SpatialVision (Enterprise Feature)'),
          child: _buildSpatialOverlay(),
        );
      default:
        return Container();
    }
  }

  Widget _buildThriftOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Align Barcode here', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildShelfOverlay() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Chip(
              label: Text('Shelf Mode'),
              backgroundColor: AppColors.primary,
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) => Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary, width: 1),
                color: AppColors.secondary.withOpacity(0.1),
              ),
              child: const Icon(Icons.book, color: Colors.white54),
            )),
          ),
          const SizedBox(height: 20),
          const Text('Scanning multiple spines...', style: TextStyle(color: Colors.white)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSpatialOverlay() {
    return Stack(
      children: [
        Center(
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: AppColors.tertiary, width: 2)),
            ),
            child: CustomPaint(
              painter: _ARGridPainter(),
            ),
          ),
        ),
        const Positioned(
          top: 100,
          left: 50,
          child: _SpatialTag(title: 'Rare Edition', price: '$85.00', color: AppColors.tertiary),
        ),
        const Positioned(
          bottom: 150,
          right: 70,
          child: _SpatialTag(title: 'High Demand', price: '$42.00', color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildLockedOverlay(String featureName) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 64, color: AppColors.tertiary),
            const SizedBox(height: 16),
            Text(featureName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Upgrade to Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    final modes = ['THRIFT', 'SHELF', 'SPATIAL'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(modes.length, (index) {
        final isSelected = _selectedMode == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ChoiceChip(
            label: Text(modes[index]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedMode = index);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
          ),
        );
      }),
    );
  }
}

class _SpatialTag extends StatelessWidget {
  const _SpatialTag({required this.title, required this.price, required this.color});
  final String title;
  final String price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ARGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tertiary.withOpacity(0.3)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    for (var i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
