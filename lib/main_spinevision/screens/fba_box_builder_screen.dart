import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class FBABoxBuilderScreen extends StatefulWidget {
  const FBABoxBuilderScreen({super.key});

  @override
  State<FBABoxBuilderScreen> createState() => _FBABoxBuilderScreenState();
}

class _FBABoxBuilderScreenState extends State<FBABoxBuilderScreen> {
  final List<BookModel> _boxItems = [];
  double _currentWeight = 0.0;
  final double _targetWeight = 45.0;
  final double _maxWeight = 50.0;
  bool _isOptimizing = false;
  String? _logisticsAdvice;
  String? _efficiencyGain;

  void _addFromInventory(BookModel book) {
    if (_boxItems.any((item) => item.isbn == book.isbn)) return;
    
    setState(() {
      _boxItems.add(book);
      _currentWeight += book.weightLbs ?? 1.2;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _currentWeight -= _boxItems[index].weightLbs ?? 1.2;
      _boxItems.removeAt(index);
      _logisticsAdvice = null;
      _efficiencyGain = null;
    });
  }

  Future<void> _runAIOptimizer() async {
    setState(() => _isOptimizing = true);
    
    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final inventory = await repository.getBooks();
      
      final result = await repository.optimizeBox(inventory, _currentWeight);
      
      if (mounted) {
        final List<dynamic> suggestedIds = result['suggested_item_ids'] ?? [];
        
        for (var id in suggestedIds) {
          try {
            final book = inventory.firstWhere((b) => b.id == id || b.isbn == id);
            if (!_boxItems.any((item) => item.isbn == book.isbn)) {
              _addFromInventory(book);
            }
          } catch (e) {
            // Ignore if ID not found exactly
          }
        }

        setState(() {
          _isOptimizing = false;
          _logisticsAdvice = result['logistics_advice'];
          _efficiencyGain = result['shipping_efficiency_gain'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Box Optimized: ${_efficiencyGain ?? "High"} efficiency gain!'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOverWeight = _currentWeight > _maxWeight;
    bool isOptimal = _currentWeight >= 40.0 && _currentWeight <= 45.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LogisticsVision'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isOptimizing ? null : _runAIOptimizer, 
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Box Optimizer',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeightDashboard(isOverWeight, isOptimal),
          if (_logisticsAdvice != null) _buildAdvicePanel(),
          Expanded(
            child: _boxItems.isEmpty 
              ? _buildEmptyState() 
              : _buildItemList(),
          ),
          _buildActionPanel(isOptimal),
        ],
      ),
    );
  }

  Widget _buildWeightDashboard(bool isOver, bool isOptimal) {
    Color statusColor = isOver ? AppColors.error : isOptimal ? AppColors.secondary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SHIPMENT WEIGHT', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondaryText, fontSize: 10)),
              Text('${_currentWeight.toStringAsFixed(1)} / $_maxWeight lbs', style: AppTextStyles.titleLarge.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentWeight / _maxWeight).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isOver ? Icons.warning : Icons.check_circle, size: 14, color: statusColor),
              const SizedBox(width: 8),
              Text(
                isOver ? 'OVERWEIGHT LIMIT' : isOptimal ? 'OPTIMAL UPS/FBA WEIGHT' : 'TARGET: 40-45 LBS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvicePanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text('AI LOGISTICS ADVICE', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_logisticsAdvice!, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.all_inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No items in this shipment.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showInventoryPicker,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('SELECT FROM INVENTORY'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInventoryPicker() async {
     final repository = RepositoryProvider.of<BookRepository>(context);
     final inventory = await repository.getBooks();
     
     if (!mounted) return;

     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
       builder: (context) => DraggableScrollableSheet(
         expand: false,
         initialChildSize: 0.7,
         builder: (context, scrollController) => Container(
           padding: const EdgeInsets.all(20),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text('Inventory Hub', style: AppTextStyles.headlineMedium),
               const SizedBox(height: 16),
               Expanded(
                 child: ListView.builder(
                   controller: scrollController,
                   itemCount: inventory.length,
                   itemBuilder: (context, i) => ListTile(
                     leading: const Icon(Icons.book, color: AppColors.primary),
                     title: Text(inventory[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                     subtitle: Text('${inventory[i].weightLbs ?? 1.2} lbs'),
                     trailing: const Icon(Icons.add_circle_outline),
                     onTap: () {
                       _addFromInventory(inventory[i]);
                       Navigator.pop(context);
                     },
                   ),
                 ),
               ),
             ],
           ),
         ),
       ),
     );
  }

  Widget _buildItemList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _boxItems.length,
      itemBuilder: (context, index) {
        final item = _boxItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.secondaryBackground, child: Icon(Icons.book, size: 18, color: AppColors.primary)),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
            subtitle: Text('${item.weightLbs ?? 1.2} lbs', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
              onPressed: () => _removeItem(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionPanel(bool isOptimal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('BACK'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _boxItems.isEmpty || _currentWeight > _maxWeight ? null : () {
                _showLabelPreview();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('PRINT FBA LABELS'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLabelPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FBA Label Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FBA SHIPMENT: FBA17Z8PQ9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  const SizedBox(height: 8),
                  const Placeholder(fallbackHeight: 80),
                  const SizedBox(height: 12),
                  Text('WEIGHT: ${_currentWeight.toStringAsFixed(1)} lbs', style: const TextStyle(fontSize: 12)),
                  const Text('BOX 1 OF 1', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shipment Finalized! Labels sent to printer.')));
            }, 
            child: const Text('CONFIRM & PRINT')
          ),
        ],
      ),
    );
  }
}
