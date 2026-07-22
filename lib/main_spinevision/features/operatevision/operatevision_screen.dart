import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class OperateVisionScreen extends StatelessWidget {
  const OperateVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OperateVision'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
              Tab(icon: Icon(Icons.map), text: 'Locate'),
              Tab(icon: Icon(Icons.people), text: 'CRM'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [
            _InventoryTab(),
            _LocateTab(),
            _CRMTab(),
          ],
        ),
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.book),
            title: Text('Book Title $index'),
            subtitle: Text('SKU: BK-2023-${100 + index} | Qty: ${index + 1}'),
            trailing: Text('\$${(index + 1) * 15}.99', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class _LocateTab extends StatelessWidget {
  const _LocateTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for item location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, size: 80, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('VisionLocate Map', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Shelf A, Section 3, Bin 12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Open AR Pathing'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CRMTab extends StatelessWidget {
  const _CRMTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final customers = ['John Doe', 'Jane Smith', 'Robert Brown', 'Emily Davis', 'Michael Wilson'];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customers[index]),
            subtitle: Text('Total Purchases: ${index + 2} | Rating: ⭐⭐⭐⭐⭐'),
            trailing: IconButton(
              icon: const Icon(Icons.message, color: AppColors.primary),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}
