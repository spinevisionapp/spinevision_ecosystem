part of 'membership_bloc.dart';

class MembershipState {

  const MembershipState({
    this.tier = VisionTier.free,
    this.isLoading = false,
  });
  final VisionTier tier;
  final bool isLoading;

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