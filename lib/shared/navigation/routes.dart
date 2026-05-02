import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/vision_hub_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/review_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/fba_box_builder_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/library_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/settings_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/profit_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/support_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/paywall_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/set_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/tax_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/marketing_vision_screen.dart';
import 'package:spinevision_ecosystem/mini_placeholders/bundle_vision/bundle_vision_screen.dart';
import 'package:spinevision_ecosystem/mini_placeholders/listing_vision/listing_vision_screen.dart';
import 'package:spinevision_ecosystem/mini_placeholders/price_vision/price_vision_screen.dart';
import 'package:spinevision_ecosystem/shared/widgets/omni_vision/omni_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/book_details_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/upgrade_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/promotion_screen.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SpineVisionNavigator(),
      ),
      GoRoute(
        path: '/omni_vision',
        builder: (context, state) => const OmniVisionScreen(),
      ),
      GoRoute(
        path: '/review_vision',
        builder: (context, state) {
          final books = state.extra as List<BookModel>? ?? [];
          return ReviewVisionScreen(scannedBooks: books);
        },
      ),
      GoRoute(
        path: '/vision_hub',
        builder: (context, state) => const VisionHubScreen(),
      ),
      GoRoute(
        path: '/fba_box_builder',
        builder: (context, state) => const FBABoxBuilderScreen(),
      ),
      GoRoute(
        path: '/profit_vision',
        builder: (context, state) => const ProfitVisionScreen(),
      ),
      GoRoute(
        path: '/bundle_vision',
        builder: (context, state) => const BundleVisionScreen(),
      ),
      GoRoute(
        path: '/listing_vision',
        builder: (context, state) {
          final book = state.extra as BookModel?;
          return ListingVisionScreen(initialBook: book);
        },
      ),
      GoRoute(
        path: '/price_vision',
        builder: (context, state) => const PriceVisionScreen(),
      ),
      GoRoute(
        path: '/set_vision',
        builder: (context, state) => const SetVisionScreen(),
      ),
      GoRoute(
        path: '/tax_vision',
        builder: (context, state) => const TaxVisionScreen(),
      ),
      GoRoute(
        path: '/marketing_vision',
        builder: (context, state) => const MarketingVisionScreen(),
      ),
      GoRoute(
        path: '/book_details',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return BookDetailsScreen(book: book);
        },
      ),
      GoRoute(
        path: '/upgrade',
        builder: (context, state) => const UpgradeScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/promotion',
        builder: (context, state) => const PromotionScreen(),
      ),
      GoRoute(
        path: '/support_vision',
        builder: (context, state) => const SupportVisionScreen(),
      ),
    ],
  );
}

class SpineVisionNavigator extends StatefulWidget {
  const SpineVisionNavigator({super.key});

  @override
  State<SpineVisionNavigator> createState() => _SpineVisionNavigatorState();
}

class _SpineVisionNavigatorState extends State<SpineVisionNavigator> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => <Widget>[
        const VisionHubScreen(), // Hub Tab
        _buildOmniVisionTab(), // OmniVision Tab
        const ListingVisionScreen(), // Listings Tab
        const SetVisionScreen(), // Sets Tab
        const MarketingVisionScreen(), // Marketing Tab
      ];

  Widget _buildOmniVisionTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColors.secondary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Icon(Icons.auto_awesome, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'OmniVision',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                foreground: Paint()..shader = AppColors.primaryGradient.createShader(
                  const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Precision, Batch, and AR Discovery',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
            ),
            const SizedBox(height: 48),
            _buildActionButton(
              onPressed: () => context.push('/omni_vision'),
              icon: Icons.camera_alt,
              label: 'OPEN OMNI SCANNER',
              gradient: AppColors.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.hub),
            label: 'Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'OmniVision',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Sets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Marketing',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
