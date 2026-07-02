import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/blocs/membership/membership_bloc.dart';

enum VisionTier { free, mid, top }

class FeatureGate extends StatelessWidget {

  const FeatureGate({
    super.key,
    required this.child,
    required this.requiredTier,
    this.lockedPlaceholder,
  });
  final Widget child;
  final VisionTier requiredTier;
  final Widget? lockedPlaceholder;

  @override
  Widget build(BuildContext context) {
    // This would logicially check against your RevenueCat / Firestore state
    final userTier = context.watch<MembershipBloc>().state.tier;

    if (_hasAccess(userTier, requiredTier)) {
      return child;
    }

    return lockedPlaceholder ?? _DefaultLockedUI(requiredTier: requiredTier);
  }

  bool _hasAccess(VisionTier current, VisionTier required) {
    return current.index >= required.index;
  }
}

class _DefaultLockedUI extends StatelessWidget {
  const _DefaultLockedUI({required this.requiredTier});
  final VisionTier requiredTier;

  @override
  Widget build(BuildContext context) => const Center(child: Text('Upgrade to access this Vision module'));
}