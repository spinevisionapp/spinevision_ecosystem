import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_model.freezed.dart';
part 'book_model.g.dart';

@freezed
class BookModel with _$BookModel {
  const factory BookModel({
    String? id,
    required String isbn,
    required String title,
    required String author,
    String? publisher,
    String? coverImageUrl,
    double? purchasePrice,
    double? weightLbs,
    int? salesRank,
    DateTime? dateSourced,
    ScrapedData? scrapedData,
    @Default({}) Map<String, ListingStatus> listingStatuses,
    DateTime? lastMarketCheck,
    double? previousValue,
  }) = _BookModel;

  factory BookModel.fromJson(Map<String, dynamic> json) => _$BookModelFromJson(json);
}

@freezed
class ScrapedData with _$ScrapedData {
  const factory ScrapedData({
    double? originalRetailPrice,
    int? salesRank,
    String? demandLevel,
    List<MarketplacePrice>? competitivePrices,
  }) = _ScrapedData;

  factory ScrapedData.fromJson(Map<String, dynamic> json) => _$ScrapedDataFromJson(json);
}

@freezed
class MarketplacePrice with _$MarketplacePrice {
  const factory MarketplacePrice({
    required String marketplace,
    required double price,
    required String url,
  }) = _MarketplacePrice;

  factory MarketplacePrice.fromJson(Map<String, dynamic> json) => _$MarketplacePriceFromJson(json);
}

enum ListingStatus { none, drafted, active, sold }

@freezed
class ExpenseModel with _$ExpenseModel {
  const factory ExpenseModel({
    String? id,
    required String merchant,
    required double amount,
    required DateTime date,
    required String category,
    String? notes,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => _$ExpenseModelFromJson(json);
}

@freezed
class SeriesModel with _$SeriesModel {
  const factory SeriesModel({
    String? id,
    required String name,
    required int totalVolumes,
    @Default([]) List<String> foundVolumes,
    @Default([]) List<String> missingVolumes,
    @Default(1.5) double setBonusMultiplier,
  }) = _SeriesModel;

  factory SeriesModel.fromJson(Map<String, dynamic> json) => _$SeriesModelFromJson(json);
}

@freezed
class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    String? id,
    required String userId,
    required String subject,
    required String message,
    @Default('Open') String status,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);
}

@freezed
class WishModel with _$WishModel {
  const factory WishModel({
    String? id,
    required String isbn,
    String? title,
    String? author,
    required double targetProfit,
    @Default(true) bool isActive,
  }) = _WishModel;

  factory WishModel.fromJson(Map<String, dynamic> json) => _$WishModelFromJson(json);
}

@freezed
class BundleModel with _$WishModel {
  const factory BundleModel({
    String? id,
    required String bundleTitle,
    required List<String> bookIds,
    required double suggestedPrice,
    String? marketingStrategy,
    @Default('Draft') String status,
  }) = _BundleModel;

  factory BundleModel.fromJson(Map<String, dynamic> json) => _$BundleModelFromJson(json);
}
