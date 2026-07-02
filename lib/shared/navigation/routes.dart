import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/vision_hub_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/vision_crm_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/vision_locate_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/forecast_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/library_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/marketing_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/profit_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/support_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/tax_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/wish_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/upgrade_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/screens/book_details_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/features/bundle_vision/bundle_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/features/listing_vision/listing_vision_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/features/shelf_vision_pro/shelf_vision_pro_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/features/amazon_vision/amazon_vision_dashboard.dart';
import 'package:spinevision_ecosystem/main_spinevision/features/amazon_vision/fba_box_builder_screen.dart';
import 'package:spinevision_ecosystem/main_spinevision/features/omnivision/screens/thrift_vision_screen.dart';

/// AppRouter defines the declarative routing logic for the SpineVision ecosystem.
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const VisionHubScreen(),
        routes: [
          GoRoute(
            path: 'omni_vision',
            builder: (context, state) => const ThriftVisionScreen(),
          ),
          GoRoute(
            path: 'pro-scan',
            builder: (context, state) => const ShelfVisionProScreen(),
          ),
          GoRoute(
            path: 'library_vision',
            builder: (context, state) => const LibraryVisionScreen(),
          ),
          GoRoute(
            path: 'listing_vision',
            builder: (context, state) => const ListingVisionScreen(),
          ),
          GoRoute(
            path: 'bundle_vision',
            builder: (context, state) => const BundleVisionScreen(),
          ),
          GoRoute(
            path: 'profit_vision',
            builder: (context, state) => const ProfitVisionScreen(),
          ),
          GoRoute(
            path: 'amazon_vision',
            builder: (context, state) => const AmazonVisionDashboard(),
          ),
          GoRoute(
            path: 'fba_box_builder',
            builder: (context, state) => const FBABoxBuilderScreen(),
          ),
          GoRoute(
            path: 'tax_vision',
            builder: (context, state) => const TaxVisionScreen(),
          ),
          GoRoute(
            path: 'crm_vision',
            builder: (context, state) => const VisionCrmScreen(),
          ),
          GoRoute(
            path: 'locate_vision',
            builder: (context, state) => const VisionLocateScreen(),
          ),
          GoRoute(
            path: 'forecast_vision',
            builder: (context, state) => const ForecastVisionScreen(),
          ),
          GoRoute(
            path: 'wish_vision',
            builder: (context, state) => const WishVisionScreen(),
          ),
          GoRoute(
            path: 'marketing_vision',
            builder: (context, state) => const MarketingVisionScreen(),
          ),
          GoRoute(
            path: 'support_vision',
            builder: (context, state) => const SupportVisionScreen(),
          ),
          GoRoute(
            path: 'upgrade',
            builder: (context, state) => const UpgradeScreen(),
          ),
          GoRoute(
            path: 'book_details',
            builder: (context, state) => BookDetailsScreen(
              book: state.extra as dynamic,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
