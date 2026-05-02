import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/services/storage_service.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class TaxVisionScreen extends StatefulWidget {
  const TaxVisionScreen({super.key});

  @override
  State<TaxVisionScreen> createState() => _TaxVisionScreenState();
}

class _TaxVisionScreenState extends State<TaxVisionScreen> {
  bool _isProcessing = false;
  double _ytdCogs = 4250.00;
  double _taxLiability = 637.50;
  
  final List<Map<String, dynamic>> _recentExpenses = [
    {'merchant': 'Goodwill', 'date': 'Oct 24', 'amount': 45.20, 'category': 'COGS'},
    {'merchant': 'Salvation Army', 'date': 'Oct 22', 'amount': 12.00, 'category': 'COGS'},
    {'merchant': 'USPS', 'date': 'Oct 20', 'amount': 8.40, 'category': 'Shipping'},
  ];

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final storage = RepositoryProvider.of<CloudStorageService>(context);

      final gcsUri = await storage.uploadImage(File(image.path));
      if (gcsUri == null) throw Exception('Upload failed');

      final result = await repository.extractReceipt(gcsUri);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _recentExpenses.insert(0, {
            'merchant': result['merchant_name'] ?? 'Unknown',
            'date': 'TODAY',
            'amount': (result['total_amount'] as num?)?.toDouble() ?? 0.0,
            'category': result['category'] ?? 'COGS',
          });
          _ytdCogs += (result['total_amount'] as num?)?.toDouble() ?? 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt Analyzed & Saved to Ledger'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaxVision Ledger'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialSummary(),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Expenses'),
            _buildExpenseList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _scanReceipt,
        backgroundColor: AppColors.primary,
        icon: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.receipt_long, color: Colors.white),
        label: Text(_isProcessing ? 'ANALYZING...' : 'SCAN RECEIPT', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('YTD COGS', '\$${_ytdCogs.toStringAsFixed(2)}', AppColors.primary),
              _buildMetric('TAX EST.', '\$${_taxLiability.toStringAsFixed(2)}', AppColors.error),
            ],
          ),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reseller Efficiency Score', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('94%', style: AppTextStyles.titleLarge.copyWith(color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondaryText)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: AppTextStyles.titleLarge),
    );
  }

  Widget _buildExpenseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentExpenses.length,
      itemBuilder: (context, index) {
        final exp = _recentExpenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.secondaryBackground,
              child: Icon(Icons.shopping_cart, color: AppColors.primary, size: 18),
            ),
            title: Text(exp['merchant'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${exp['date']} • ${exp['category']}'),
            trailing: Text(
              '-\$${(exp['amount'] as double).toStringAsFixed(2)}', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
