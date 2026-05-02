import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class BookListItem extends StatelessWidget {
  final BookModel book;

  const BookListItem({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/book_details', extra: book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    _buildPricingRow(),
                    const SizedBox(height: 8),
                    _buildChannelBadges(),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.coverImageUrl != null
            ? Image.network(book.coverImageUrl!, fit: BoxFit.cover)
            : const Icon(Icons.book, size: 30, color: Colors.grey),
      ),
    );
  }

  Widget _buildPricingRow() {
    return Row(
      children: [
        Text(
          '\$${(book.scrapedData?.originalRetailPrice ?? 0.0).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 14),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: const Text('PROFITS ACTIVE', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildChannelBadges() {
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
          fontSize: 7, 
          fontWeight: FontWeight.bold, 
          color: (status == ListingStatus.none || isDraft) ? AppColors.secondaryText : Colors.white
        ),
      ),
    );
  }
}
