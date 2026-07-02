import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_model.freezed.dart';
part 'book_model.g.dart';

@freezed
abstract class BookModel with _$BookModel {
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
    @Default(false) bool isSigned,
    String? signatureImageRef,
    String? titleLowercase,
  }) = _BookModel;

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);
}

@freezed
abstract class CustomerModel with _$CustomerModel {
  const factory CustomerModel({
    String? id,
    required String name,
    required String email,
    String? phone,
    @Default([]) List<String> purchaseHistoryIds,
    String? notes,
    DateTime? lastInteraction,
  }) = _CustomerModel;

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
}

@freezed
abstract class LocationModel with _$LocationModel {
  const factory LocationModel({
    String? id,
    required String shelfId,
    required String binId,
    String? section,
    @Default([]) List<String> bookIds,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
}

@freezed
abstract class ForecastModel with _$ForecastModel {
  const factory ForecastModel({
    String? id,
    required String category,
    required double projectedMarketValue,
    required String seasonalDemand,
    @Default([]) List<String> priceProjections,
    DateTime? updatedAt,
  }) = _ForecastModel;

  factory ForecastModel.fromJson(Map<String, dynamic> json) =>
      _$ForecastModelFromJson(json);
}

@freezed
abstract class MileageModel with _$MileageModel {
  const factory MileageModel({
    String? id,
    required DateTime date,
    required String startLocation,
    required String endLocation,
    required double miles,
    required String purpose,
  }) = _MileageModel;

  factory MileageModel.fromJson(Map<String, dynamic> json) =>
      _$MileageModelFromJson(json);
}

@freezed
abstract class ScrapedData with _$ScrapedData {
  const factory ScrapedData({
    double? originalRetailPrice,
    int? salesRank,
    String? demandLevel,
    List<MarketplacePrice>? competitivePrices,
  }) = _ScrapedData;

  factory ScrapedData.fromJson(Map<String, dynamic> json) =>
      _$ScrapedDataFromJson(json);
}

@freezed
abstract class MarketplacePrice with _$MarketplacePrice {
  const factory MarketplacePrice({
    required String marketplace,
    required double price,
    required String url,
  }) = _MarketplacePrice;

  factory MarketplacePrice.fromJson(Map<String, dynamic> json) =>
      _$MarketplacePriceFromJson(json);
}

enum ListingStatus { none, drafted, active, sold }

@freezed
abstract class ExpenseModel with _$ExpenseModel {
  const factory ExpenseModel({
    String? id,
    required String merchant,
    required double amount,
    required DateTime date,
    required String category,
    @Default([]) List<ReceiptItem> items,
    String? notes,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);
}

@freezed
abstract class ReceiptItem with _$ReceiptItem {
  const factory ReceiptItem({
    required String description,
    required int quantity,
    required double unitPrice,
    required double total,
  }) = _ReceiptItem;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
}

@freezed
abstract class SeriesModel with _$SeriesModel {
  const factory SeriesModel({
    String? id,
    required String name,
    required int totalVolumes,
    @Default([]) List<String> foundVolumes,
    @Default([]) List<String> missingVolumes,
    @Default(1.5) double setBonusMultiplier,
  }) = _SeriesModel;

  factory SeriesModel.fromJson(Map<String, dynamic> json) =>
      _$SeriesModelFromJson(json);
}

@freezed
abstract class SupportTicket with _$SupportTicket {
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

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}

@freezed
abstract class WishModel with _$WishModel {
  const factory WishModel({
    String? id,
    required String isbn,
    String? title,
    String? author,
    required double targetProfit,
    @Default(true) bool isActive,
  }) = _WishModel;

  factory WishModel.fromJson(Map<String, dynamic> json) =>
      _$WishModelFromJson(json);
}

@freezed
abstract class BundleModel with _$BundleModel {
  const factory BundleModel({
    String? id,
    required String bundleTitle,
    required List<String> bookIds,
    required double suggestedPrice,
    String? marketingStrategy,
    @Default('Draft') String status,
  }) = _BundleModel;

  factory BundleModel.fromJson(Map<String, dynamic> json) =>
      _$BundleModelFromJson(json);
}
