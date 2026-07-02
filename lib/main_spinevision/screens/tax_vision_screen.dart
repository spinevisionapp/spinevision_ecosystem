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
  
  final List<Map<String, dynamic>> _recentExpenses = [
    {'merchant': 'Goodwill', 'date': 'Oct 24', 'amount': 45.20, 'category': 'COGS'},
    {'merchant': 'Salvation Army', 'date': 'Oct 22', 'amount': 12.00, 'category': 'COGS'},
    {'merchant': 'USPS', 'date': 'Oct 20', 'amount': 8.40, 'category': 'Shipping'},
  ];

  void _showLogTripDialog() {
    final TextEditingController milesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Sourcing Trip'),
        content: TextField(
          controller: milesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Miles Driven',
            hintText: '0.0',
            suffixText: 'mi',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final miles = double.tryParse(milesController.text) ?? 0.0;
              if (miles > 0) {
                context.read<BookRepository>().addMileage(miles);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged $miles miles sourcing trip.')),
                );
              }
            },
            child: const Text('SAVE TRIP'),
          ),
        ],
      ),
    );
  }

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
    final repository = context.watch<BookRepository>();
    final ytdCogs = repository.ytdCogs;
    final loggedMiles = repository.loggedMiles;
    final taxLiability = ytdCogs * 0.15; // Estimated 15% self-employment tax

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
            _buildFinancialSummary(ytdCogs, taxLiability),
            const SizedBox(height: 32),
            _buildMileageSection(loggedMiles),
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

  Widget _buildFinancialSummary(double ytdCogs, double taxLiability) {
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
              _buildMetric('YTD COGS', '\$${ytdCogs.toStringAsFixed(2)}', AppColors.primary),
              _buildMetric('TAX EST.', '\$${taxLiability.toStringAsFixed(2)}', AppColors.error),
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

  Widget _buildMileageSection(double loggedMiles) {
    final deduction = loggedMiles * 0.67;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AUTO-MILEAGE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ElevatedButton(
                onPressed: _showLogTripDialog, 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(0, 32)),
                child: const Text('LOG TRIP', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loggedMiles.toStringAsFixed(0), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('TOTAL MILES', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${deduction.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Text('DEDUCTION', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
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
