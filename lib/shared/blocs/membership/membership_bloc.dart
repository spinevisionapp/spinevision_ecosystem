import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:spinevision_ecosystem/shared/widgets/feature_gate.dart';
import 'package:spinevision_ecosystem/shared/services/auth_service.dart';

part 'membership_event.dart';
part 'membership_state.dart';

class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  final AuthService _authService;
  late final void Function(CustomerInfo) _customerInfoListener;
  StreamSubscription? _authSubscription;

  MembershipBloc(this._authService) : super(const MembershipState()) {
    on<MembershipStarted>(_onStarted);
    on<MembershipUpdated>(_onUpdated);

    // Listen to real-time updates from RevenueCat
    _customerInfoListener = (info) {
      add(MembershipUpdated(info));
    };
    Purchases.addCustomerInfoUpdateListener(_customerInfoListener);

    // Listen to auth changes to sync with RevenueCat
    _authSubscription = _authService.user.listen((user) {
      if (user != null) {
        Purchases.logIn(user.uid);
      } else {
        Purchases.logOut();
      }
    });
  }

  Future<void> _onStarted(MembershipStarted event, Emitter<MembershipState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      emit(state.copyWith(
        tier: _mapEntitlementsToTier(customerInfo),
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onUpdated(MembershipUpdated event, Emitter<MembershipState> emit) {
    emit(state.copyWith(tier: _mapEntitlementsToTier(event.customerInfo)));
  }

  VisionTier _mapEntitlementsToTier(CustomerInfo info) {
    if (info.entitlements.all['top_tier']?.isActive ?? false) return VisionTier.top;
    if (info.entitlements.all['mid_tier']?.isActive ?? false) return VisionTier.mid;
    return VisionTier.free;
  }

  @override
  Future<void> close() {
    Purchases.removeCustomerInfoUpdateListener(_customerInfoListener);
    _authSubscription?.cancel();
    return super.close();
  }
}