// ============================================================================
// FILE: lib/features/auth/data/models/user_model.dart
// NOTE: Groups are sourced ONLY from the single 'group' field in the response.
//       We no longer derive from 'primary_group' or 'rental_groups'.
// ============================================================================
import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.partnerId,
    required super.partnerDisplayName,
    required super.isInternalUser,
    required super.isAdmin,
    required super.database,
    required super.primaryGroup,
    required super.userContext,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Use ONLY the 'group' field from backend for routing roles.
    // Examples:
    //   group: "group_rental_tenant"
    //   group: "group_rental_landlord"
    // If absent, default to empty string.
    final String primaryGroup = (json['group'] ?? '').toString().trim();

    if (kDebugMode) {
      try {
        debugPrint('UserModel.fromJson group: $primaryGroup');
        debugPrint(
          'UserModel.fromJson uid: ${json['uid']}, name: ${json['name']}',
        );
      } catch (_) {}
    }

    return UserModel(
      id: json['uid'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      partnerId: json['partner_id'] ?? 0,
      partnerDisplayName: json['partner_display_name'] ?? '',
      isInternalUser: json['is_internal_user'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      database: json['db'] ?? '',
      primaryGroup: primaryGroup,
      userContext: Map<String, dynamic>.from(json['user_context'] ?? {}),
      // Not used for routing anymore; keep as empty for compatibility.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'name': name,
      'username': username,
      'partner_id': partnerId,
      'partner_display_name': partnerDisplayName,
      'is_internal_user': isInternalUser,
      'is_admin': isAdmin,
      'db': database,
      // Persist the single source of truth for role
      'group': primaryGroup,
      'user_context': userContext,
      // Kept for shape compatibility if needed downstream
    };
  }
}
