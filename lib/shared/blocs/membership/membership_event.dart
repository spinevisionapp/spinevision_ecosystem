part of 'membership_bloc.dart';

sealed class MembershipEvent {}

class MembershipStarted extends MembershipEvent {}

class MembershipUpdated extends MembershipEvent {
  MembershipUpdated(this.customerInfo);
  final CustomerInfo customerInfo;
}