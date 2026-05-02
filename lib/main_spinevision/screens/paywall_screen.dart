import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePurchase(Package package) async {
    setState(() => _isLoading = true);
    try {
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      if (result.customerInfo.entitlements.active.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Premium Vision!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpineVision Premium'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Scale Your Sourcing Business',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gain access to real-time BOLO feeds, shelf-scanning, and advanced AR spatial analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 32),
                  ...packages.map((package) => _buildPackageCard(package)),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Not right now', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(package.storeProduct.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(package.storeProduct.description),
        trailing: Text(package.storeProduct.priceString, 
          style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
        onTap: () => _handlePurchase(package),
      ),
    );
  }
}