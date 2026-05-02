import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/widgets/gated_feature.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';
import 'package:go_router/go_router.dart';

class VisionHubScreen extends StatefulWidget {
  const VisionHubScreen({super.key});

  @override
  State<VisionHubScreen> createState() => _VisionHubScreenState();
}

class _VisionHubScreenState extends State<VisionHubScreen> {
  bool _isLoadingAnalytics = true;
  Map<String, dynamic>? _analyticsData;
  String? _analyticsError;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final analytics = await repository.getAnalytics();
      if (mounted) {
        setState(() {
          _analyticsData = analytics;
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyticsError = e.toString();
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<BookRepository>(context);
    final tier = repository.currentTier;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VisionHub'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'INSIGHTS', icon: Icon(Icons.auto_awesome)),
              Tab(text: 'INVENTORY', icon: Icon(Icons.inventory_2)),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildInsightsTab(tier),
            _buildInventoryTab(repository),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(String tier) {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_analyticsError != null) {
      return Center(child: Text('Error: $_analyticsError'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryGrid(tier),
          const SizedBox(height: 24),
          _buildMarketWatchSection(tier),
          const SizedBox(height: 24),
          _buildSectionHeader('BOLO Alerts & Trends'),
          GatedFeature(
            currentTier: tier,
            requiredTier: 'Pro',
            featureName: 'VisionHub BOLO Feed',
            child: _buildInsightsCard(),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Performance Trends'),
          GatedFeature(
            currentTier: tier,
            requiredTier: 'Pro',
            featureName: 'Performance Trends',
            child: Column(
              children: [
                _buildSimpleBarChart(),
                const SizedBox(height: 24),
                _buildSectionHeader('Inventory Mix'),
                _buildCategoryDistribution(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isRepricing = false;
  List<dynamic> _repriceAlerts = [];

  Widget _buildMarketWatchSection(String tier) {
    return GatedFeature(
      currentTier: tier,
      requiredTier: 'Pro',
      featureName: 'RepriceVision Market Watch',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('RepriceVision Alerts'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              children: [
                if (_repriceAlerts.isEmpty)
                  Column(
                    children: [
                      const Icon(Icons.speed, color: Colors.grey, size: 40),
                      const SizedBox(height: 12),
                      const Text('No price increases detected yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isRepricing ? null : _runRepriceVision,
                        icon: _isRepricing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 16),
                        label: const Text('RUN MARKET WATCH'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _repriceAlerts.length,
                    itemBuilder: (context, i) {
                      final alert = _repriceAlerts[i];
                      return ListTile(
                        leading: const Icon(Icons.arrow_upward, color: Colors.green),
                        title: Text(alert['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(alert['reason'], style: const TextStyle(fontSize: 11)),
                        trailing: Text('+${alert['price_delta_percent']}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runRepriceVision() async {
    setState(() => _isRepricing = true);
    try {
      final repository = RepositoryProvider.of<BookRepository>(context);
      final result = await repository.repriceInventory();
      if (mounted) {
        setState(() {
          _repriceAlerts = result['alerts'] ?? [];
          _isRepricing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRepricing = false);
    }
  }

  Widget _buildInventoryTab(BookRepository repository) {
    return StreamBuilder<List<BookModel>>(
      stream: repository.getInventoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Your inventory is empty.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/omni_vision'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('START SOURCING'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RECENT ITEMS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                  TextButton.icon(
                    onPressed: () => context.push('/library_vision'), 
                    icon: const Icon(Icons.library_books, size: 16), 
                    label: const Text('VIEW FULL LIBRARY'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: books.length > 10 ? 10 : books.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: book.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(book.coverImageUrl!, width: 40, height: 60, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 40,
                        height: 60,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.book, color: Colors.grey),
                      ),
                title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${book.author} • ISBN: ${book.isbn}', style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 6),
                    _buildChannelBadges(book),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${(book.scrapedData?.originalRetailPrice ?? 0.0).toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const Text('RETAIL', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                onTap: () {
                   context.push('/listing_vision', extra: book);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChannelBadges(BookModel book) {
    return Row(
      children: [
        _buildBadge('eBay', book.listingStatuses['eBay'] ?? ListingStatus.none),
        const SizedBox(width: 4),
        _buildBadge('AMZ', book.listingStatuses['Amazon'] ?? ListingStatus.none),
        const SizedBox(width: 4),
        _buildBadge('FBM', book.listingStatuses['FBMarketplace'] ?? ListingStatus.none),
      ],
    );
  }

  Widget _buildBadge(String label, ListingStatus status) {
    Color color;
    bool isDraft = false;
    
    switch (status) {
      case ListingStatus.active:
        color = AppColors.secondary;
        break;
      case ListingStatus.drafted:
        color = AppColors.secondary.withValues(alpha: 0.5);
        isDraft = true;
        break;
      case ListingStatus.sold:
        color = AppColors.primary;
        break;
      case ListingStatus.none:
      default:
        color = Colors.grey.shade300;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDraft ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(4),
        border: isDraft ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8, 
          fontWeight: FontWeight.bold, 
          color: (status == ListingStatus.none || isDraft) ? AppColors.secondaryText : Colors.white
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(String tier) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricCard('PROFIT (YTD)', tier == 'Hobbyist' ? '---' : '\$${(_analyticsData?['projected_profit'] as num?)?.toStringAsFixed(2) ?? "0.00"}', Icons.trending_up, Colors.green),
        _buildMetricCard('EFFICIENCY', tier == 'Hobbyist' ? '---' : '${((_analyticsData?['efficiency_score'] as num?) ?? 0.0 * 100).toInt()}%', Icons.bolt, Colors.orange),
        _buildMetricCard('INV. VALUE', '\$${(_analyticsData?['total_inventory_value'] as num?)?.toStringAsFixed(2) ?? "0.00"}', Icons.inventory_2, AppColors.secondary),
        _buildMetricCard('ROI TARGET', '82%', Icons.pie_chart, AppColors.primary),
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text('AI Sourcing Tip', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_analyticsData?['sourcing_recommendations'] ?? 'Analyze more items for better insights.', style: const TextStyle(fontSize: 15)),
          const Divider(height: 32, thickness: 1),
          const Text('Market Trends', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          ...((_analyticsData?['market_trends'] as List<dynamic>?)?.map((t) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )) ??
              [const Text('No trends identified yet.')]),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSimpleBarChart() {
    final data = [40, 70, 50, 90, 60, 100, 80];
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((h) => Container(
          width: 20,
          height: h * 1.4,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final categories = [
      {'label': 'Fiction', 'pct': 0.45, 'color': AppColors.primary},
      {'label': 'Philosophy', 'pct': 0.25, 'color': AppColors.secondary},
      {'label': 'History', 'pct': 0.15, 'color': Colors.orange},
      {'label': 'Other', 'pct': 0.15, 'color': Colors.grey},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: categories.map((c) => Expanded(
                  flex: ((c['pct'] as double) * 100).toInt(),
                  child: Container(color: c['color'] as Color),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, color: c['color'] as Color),
                const SizedBox(width: 8),
                Text(c['label'] as String),
                const Spacer(),
                Text('${((c['pct'] as double) * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
