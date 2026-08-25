import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/app_theme.dart';

class ThriftVisionScreen extends StatefulWidget {
  const ThriftVisionScreen({super.key});

  @override
  State<ThriftVisionScreen> createState() => _ThriftVisionScreenState();
}

class _ThriftVisionScreenState extends State<ThriftVisionScreen> {
  bool _isScanning = false;
  bool _isSpatialMode = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _processImage(XFile image) async {
    if (!mounted) {
      return;
    }

    try {
      setState(() => _isScanning = true);
      final repository = context.read<BookRepository>();

      final result = await repository.getRecommendation(image.path, {
        'min_profit': 10.0,
      });

      if (!mounted) return;
      setState(() => _isScanning = false);

      final decision = result['decision'] as String? ?? 'UNKNOWN';
      final profit = (result['profit_estimate'] as num?)?.toDouble() ?? 0.0;
      final demand = result['demand_score'] as int? ?? 0;
      final promo = result['promo_update'] as String?;

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          height: 350,
          child: Column(
            children: [
              Icon(
                decision == 'BUY' ? Icons.check_circle : Icons.do_not_disturb,
                color: decision == 'BUY' ? AppTheme.secondaryTeal : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                '$decision RECOMMENDATION',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (profit > 15.0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rocket_launch, color: AppTheme.primaryPurple, size: 14),
                      SizedBox(width: 8),
                      Text('AMAZON ELIGIBLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                    ],
                  ),
                ),
              Text('Estimated Profit: \$${profit.toStringAsFixed(2)}'),
              Text('Demand Score: $demand/100'),
              if (promo != null && promo.contains('GRANTING'))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'PROMO UNLOCKED!\n$promo',
                    style: const TextStyle(
                      color: AppTheme.secondaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Add to Library'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      await _processImage(image);
    }
  }

  void _showImageSourceSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(bc);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(bc);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isSpatialMode ? 'SpatialVision AR' : 'OmniVision: Fast Scan'),
        actions: [
          Row(
            children: [
              const Text('SPATIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Switch(
                value: _isSpatialMode,
                onChanged: (v) => setState(() => _isSpatialMode = v),
                activeColor: AppTheme.secondaryTeal,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          const Center(
            child: Text(
              'Camera Viewfinder Placeholder',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (_isSpatialMode) _buildSpatialOverlay(),
          if (_isScanning)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryTeal),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isScanning
            ? null
            : () => _showImageSourceSelection(context),
        backgroundColor: _isSpatialMode ? AppTheme.primaryPurple : AppTheme.secondaryTeal,
        child: Icon(_isSpatialMode ? Icons.auto_awesome : Icons.camera_alt, size: 40),
      ),
    );
  }

  Widget _buildSpatialOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Simulated "Buy" target
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // HUD Elements
          Positioned(
            top: 100,
            left: 20,
            child: _buildHudElement('PROFIT: +$14.50', Colors.green),
          ),
          Positioned(
            top: 140,
            left: 20,
            child: _buildHudElement('DEMAND: HIGH', Colors.blue),
          ),
          Positioned(
            bottom: 150,
            right: 20,
            child: _buildHudElement('AMAZON: ELIGIBLE', AppTheme.primaryPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildHudElement(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }
}
