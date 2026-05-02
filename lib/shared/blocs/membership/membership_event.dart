part of 'membership_bloc.dart';

sealed class MembershipEvent {}

class MembershipStarted extends MembershipEvent {}

class MembershipUpdated extends MembershipEvent {
  final CustomerInfo customerInfo;
  MembershipUpdated(this.customerInfo);
}