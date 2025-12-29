// lib/features/auth/domain/entities/user.dart

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String username;
  final int partnerId;
  final String partnerDisplayName;
  final bool isInternalUser;
  final bool isAdmin;
  final String database;
  final Map<String, dynamic> userContext;

  /// NEW: Primary role from backend
  final String primaryGroup;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.partnerId,
    required this.partnerDisplayName,
    required this.isInternalUser,
    required this.isAdmin,
    required this.database,
    required this.userContext,
    required this.primaryGroup,
  });

  // ─────────────────────────────────────────────
  // PRIMARY ROLE CHECKS (USE THESE FOR ROUTING)
  // ─────────────────────────────────────────────

  bool get isTenant => primaryGroup == 'group_rental_tenant';

  bool get isLandlord => primaryGroup == 'group_rental_landlord';

  bool get isMaintenance => primaryGroup == 'group_rental_maintenance';

  bool get isHr => primaryGroup == 'group_hr';

  bool get isInternalStaff => isInternalUser && !isTenant;

  @override
  List<Object> get props => [
    id,
    name,
    username,
    partnerId,
    partnerDisplayName,
    isInternalUser,
    isAdmin,
    database,
    primaryGroup,
  ];
}
