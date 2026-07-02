import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:provider/provider.dart';

class VisionCrmScreen extends StatelessWidget {
  const VisionCrmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context);
    // In a real app, we'd get the tier from a UserBloc or similar
    const String currentTier = 'Enterprise'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('VisionCRM'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: GatedFeature(
        currentTier: currentTier,
        requiredTier: 'Pro',
        featureName: 'VisionCRM',
        child: Column(
          children: [
            _buildCrmHeader(),
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: firestore.getCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customers = snapshot.data ?? [];
                  if (customers.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerTile(customer);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, firestore),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildCrmHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVE COLLECTORS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              SizedBox(height: 4),
              Text('24 Clients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text('INSIGHTS'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No customers found.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
          child: Text(customer.name[0], style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(customer.email, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, FirestoreService firestore) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                firestore.saveCustomer(CustomerModel(
                  name: nameController.text,
                  email: emailController.text,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
