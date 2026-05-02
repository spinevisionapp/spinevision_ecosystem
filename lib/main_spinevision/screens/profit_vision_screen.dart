import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/services/storage_service.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class ProfitVisionScreen extends StatefulWidget {
  const ProfitVisionScreen({super.key});

  @override
  State<ProfitVisionScreen> createState() => _ProfitVisionScreenState();
}

class _ProfitVisionScreenState extends State<ProfitVisionScreen> {
  bool _isTrackingMileage = false;
  double _currentTripMiles = 0.0;
  bool _isProcessingReceipt = false;

  void _toggleTracking() {
    final repository = RepositoryProvider.of<BookRepository>(context);
    setState(() {
      _isTrackingMileage = !_isTrackingMileage;
      if (_isTrackingMileage) {
        _currentTripMiles = 12.4 + (DateTime.now().minute % 5);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS Sourcing Trip Tracking Started.'), 
            backgroundColor: AppColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        repository.addMileage(_currentTripMiles);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip Ended. Added ${_currentTripMiles.toStringAsFixed(1)} miles to Profit log.'), 
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _currentTripMiles = 0.0;
      }
    });
  }

  Future<void> _onScanReceipt() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);

    if (xFile == null || !mounted) return;

    final repository = RepositoryProvider.of<BookRepository>(context);
    final storage = RepositoryProvider.of<CloudStorageService>(context);

    setState(() => _isProcessingReceipt = true);

    try {
      final gcsUri = await storage.uploadImage(File(xFile.path));
      
      if (gcsUri == null) throw Exception('Upload failed');
      
      final receiptData = await repository.extractReceipt(gcsUri);
      final amount = (receiptData['total_amount'] as num?)?.toDouble() ?? 0.0;
      
      repository.addCogs(amount);

      if (mounted) {
        setState(() => _isProcessingReceipt = false);
        _showReceiptSuccessDialog(receiptData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingReceipt = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt scan failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showReceiptSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Receipt Logged'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merchant: ${data['merchant_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Amount: \$${(data['total_amount'] as num?)?.toDouble().toStringAsFixed(2)}'),
            Text('Tax: \$${(data['tax_amount'] as num?)?.toDouble().toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text('The total has been added to your YTD COGS.', style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showCashLogDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Cash Purchase'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount Spent (\$)',
            hintText: '0.00',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                RepositoryProvider.of<BookRepository>(context).addCogs(amount);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged \$$amount cash purchase.')),
                );
              }
            },
            child: const Text('LOG PURCHASE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<BookRepository>(context);
    final tier = repository.currentTier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ProfitVision Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainProfitCard(repository, tier),
            const SizedBox(height: 24),
            _buildSectionHeader('Financial Metrics'),
            _buildMetricsGrid(repository),
            const SizedBox(height: 32),
            _buildSectionHeader('Sourcing Intelligence'),
            _buildMileageCard(),
            const SizedBox(height: 16),
            GatedFeature(
              currentTier: tier,
              requiredTier: 'Pro',
              featureName: 'AI Receipt Scanning',
              child: _buildReceiptScanner(),
            ),
            const SizedBox(height: 16),
            _buildCashPurchaseCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Monthly Export'),
            GatedFeature(
              currentTier: tier,
              requiredTier: 'Enterprise',
              featureName: 'Tax-Ready Exports',
              child: _buildExportCard(),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGrey, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildMainProfitCard(BookRepository repo, String tier) {
    bool isHobbyist = tier == 'Hobbyist';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YTD NET PROFIT',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            isHobbyist ? '\$---.--' : '\$14,250.80',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniProfitStat('Gross', isHobbyist ? '---' : '\$22,400'),
              const SizedBox(width: 24),
              _buildMiniProfitStat('Expenses', isHobbyist ? '---' : '\$8,149'),
              const Spacer(),
              const Icon(Icons.trending_up, color: Colors.white70, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProfitStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetricsGrid(BookRepository repo) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildMetricTile('COGS', '\$${repo.ytdCogs.toStringAsFixed(2)}', Icons.inventory_2, Colors.orange),
        _buildMetricTile('MILEAGE', '${repo.loggedMiles.toInt()} mi', Icons.directions_car, AppColors.primaryTeal),
        _buildMetricTile('DEDUCTIONS', '\$${(repo.loggedMiles * 0.67).toStringAsFixed(2)}', Icons.shield, Colors.blue),
        _buildMetricTile('PAYOUTS', '\$2,140', Icons.account_balance_wallet, Colors.green),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.darkGrey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMileageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isTrackingMileage ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car, 
                color: _isTrackingMileage ? Colors.green : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isTrackingMileage ? 'Sourcing Trip Active' : 'Start Sourcing Trip',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_isTrackingMileage)
                    Text('Current: ${_currentTripMiles.toStringAsFixed(1)} miles recorded', style: const TextStyle(color: Colors.green, fontSize: 12))
                  else 
                    const Text('Automatic GPS mileage logging', style: TextStyle(color: AppColors.darkGrey, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: _isTrackingMileage,
              activeThumbColor: Colors.green,
              onChanged: (val) => _toggleTracking(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptScanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.receipt_long, color: AppColors.primaryPurple),
        ),
        title: const Text('Scan Thrift Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('AI extracts cost and tax for COGS.', style: TextStyle(fontSize: 12)),
        trailing: _isProcessingReceipt 
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Icon(Icons.camera_alt, color: AppColors.primaryTeal),
        onTap: _isProcessingReceipt ? null : _onScanReceipt,
      ),
    );
  }

  Widget _buildCashPurchaseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.payments, color: Colors.orange),
        ),
        title: const Text('Log Cash Purchase', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Quick log for unreceipted garage sales.', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal),
        onTap: () => _showCashLogDialog(),
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
        ),
        title: const Text('Q1 2026 Profit Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Download full tax-ready export.', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.download, color: AppColors.darkGrey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Generating PDF Report...')),
          );
        },
      ),
    );
  }
}
