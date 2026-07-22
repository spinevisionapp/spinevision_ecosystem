import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    DateTime? publishDate,
    String? genre,
    String? format,
    String? language,
    int? pageCount,
    double? weight,
    Dimensions? dimensions,
    String? description,
    String? thumbnailUrl,
    @Default([]) List<String> tags,
    double? conditionRating,
    @Default({}) Map<String, dynamic> metadata,
  }) = _BookModel;

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);
}

@freezed
abstract class Dimensions with _$Dimensions {
  const factory Dimensions({
    double? l,
    double? w,
    double? h,
  }) = _Dimensions;

  factory Dimensions.fromJson(Map<String, dynamic> json) =>
      _$DimensionsFromJson(json);
}

@freezed
abstract class ScanModel with _$ScanModel {
  const factory ScanModel({
    String? scanId,
    required String userId,
    required DateTime timestamp,
    required String type,
    String? isbnDetected,
    String? imageRef,
    @Default({}) Map<String, dynamic> overlayData,
    String? result,
    @JsonKey(fromJson: _geoPointFromJson, toJson: _geoPointToJson)
    GeoPoint? location,
    String? sessionId,
  }) = _ScanModel;

  factory ScanModel.fromJson(Map<String, dynamic> json) =>
      _$ScanModelFromJson(json);
}

GeoPoint? _geoPointFromJson(dynamic json) => json is GeoPoint ? json : null;
dynamic _geoPointToJson(GeoPoint? geoPoint) => geoPoint;

@freezed
abstract class ListingModel with _$ListingModel {
  const factory ListingModel({
    String? listingId,
    required String userId,
    required String bookId,
    required String platform,
    String? externalId,
    required double price,
    double? shippingCost,
    required String status,
    DateTime? dateListed,
    DateTime? dateSold,
    String? notes,
    @Default([]) List<ListingHistory> history,
  }) = _ListingModel;

  factory ListingModel.fromJson(Map<String, dynamic> json) =>
      _$ListingModelFromJson(json);
}

@freezed
abstract class ListingHistory with _$ListingHistory {
  const factory ListingHistory({
    required DateTime timestamp,
    required String action,
    required String details,
  }) = _ListingHistory;

  factory ListingHistory.fromJson(Map<String, dynamic> json) =>
      _$ListingHistoryFromJson(json);
}

@freezed
abstract class BuyerModel with _$BuyerModel {
  const factory BuyerModel({
    String? buyerId,
    required String userId,
    required String name,
    required String email,
    String? phone,
    AddressModel? address,
    @Default(0) int purchaseCount,
    @Default(0.0) double totalSpent,
    @Default([]) List<String> tags,
    String? notes,
  }) = _BuyerModel;

  factory BuyerModel.fromJson(Map<String, dynamic> json) =>
      _$BuyerModelFromJson(json);
}

@freezed
abstract class AddressModel with _$AddressModel {
  const factory AddressModel({
    String? street,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) = _AddressModel;

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);
}

@freezed
abstract class SaleModel with _$SaleModel {
  const factory SaleModel({
    String? saleId,
    required String userId,
    required String listingId,
    required String buyerId,
    required double grossAmount,
    required double netAmount,
    double? fees,
    double? taxAmount,
    double? shippingPaid,
    required DateTime dateSold,
    required String paymentStatus,
    required String fulfillmentStatus,
  }) = _SaleModel;

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);
}

@freezed
abstract class AnalyticsSnapshotModel with _$AnalyticsSnapshotModel {
  const factory AnalyticsSnapshotModel({
    String? snapshotId,
    required String userId,
    required String period,
    required DateTime timestamp,
    required Map<String, double> metrics,
  }) = _AnalyticsSnapshotModel;

  factory AnalyticsSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSnapshotModelFromJson(json);
}

@freezed
abstract class UserSettingsModel with _$UserSettingsModel {
  const factory UserSettingsModel({
    required String userId,
    required String membershipTier,
    @Default({}) Map<String, dynamic> preferences,
    @Default({}) Map<String, String> apiKeys,
    DateTime? lastSync,
  }) = _UserSettingsModel;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsModelFromJson(json);
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
abstract class TagModel with _$TagModel {
  const factory TagModel({
    required String tagId,
    String? userId,
    required String label,
    required String color,
    required String category,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
}
