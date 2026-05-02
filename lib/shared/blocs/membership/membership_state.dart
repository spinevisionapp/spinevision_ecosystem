part of 'membership_bloc.dart';

class MembershipState {
  final VisionTier tier;
  final bool isLoading;

  const MembershipState({
    this.tier = VisionTier.free,
    this.isLoading = false,
  });

  MembershipState copyWith({
    VisionTier? tier,
    bool? isLoading,
  }) {
    return MembershipState(
      tier: tier ?? this.tier,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}