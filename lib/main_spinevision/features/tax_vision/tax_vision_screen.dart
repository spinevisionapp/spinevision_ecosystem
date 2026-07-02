import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class TaxVisionScreen extends StatefulWidget {
  const TaxVisionScreen({super.key});

  @override
  State<TaxVisionScreen> createState() => _TaxVisionScreenState();
}

class _TaxVisionScreenState extends State<TaxVisionScreen> {
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _scanReceipt() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      imageQuality: 90,
    );

    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final repository = context.read<BookRepository>();
      final result = await repository.extractReceipt(image.path);

      if (mounted) {
        final expense = ExpenseModel(
          merchant: result['merchant'] ?? 'Unknown Merchant',
          amount: (result['total_amount'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(result['date'] ?? '') ?? DateTime.now(),
          category: result['category'] ?? 'COGS',
          items: (result['items'] as List<dynamic>? ?? [])
              .map((item) => ReceiptItem(
                    description: item['description'] ?? '',
                    quantity: item['quantity'] ?? 1,
                    unitPrice: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
                    total: (item['total'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList(),
        );

        await repository.saveExpense(expense);
        setState(() => _isProcessing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted \$${expense.amount.toStringAsFixed(2)} from ${expense.merchant}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt extraction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<BookRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaxVision: AI Ledger'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: repository.getLedgerStream(),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? [];
          final totalCogs = expenses.where((e) => e.category == 'COGS').fold(0.0, (sum, e) => sum + e.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(totalCogs),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGrey, letterSpacing: 1.2)),
                    Text('${expenses.length} ENTRIES', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                if (expenses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.0),
                      child: Text('No expenses logged yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...expenses.map((e) => _buildExpenseCard(e)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _scanReceipt,
        label: _isProcessing 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('SCAN RECEIPT', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: _isProcessing ? null : const Icon(Icons.receipt_long),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  Widget _buildHeader(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet, color: AppColors.primaryPurple, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL COGS (YTD)', style: TextStyle(color: AppColors.darkGrey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryTeal),
        ),
        title: Text(expense.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${expense.date.month}/${expense.date.day}/${expense.date.year} • ${expense.items.length} items'),
        trailing: Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPurple),
        ),
        children: [
          if (expense.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  const Divider(),
                  ...expense.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.description, style: const TextStyle(fontSize: 13))),
                            Text('${item.quantity}x', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 12),
                            Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
