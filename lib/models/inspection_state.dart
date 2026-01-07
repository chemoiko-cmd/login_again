import 'package:flutter/material.dart';

enum InspectionState {
  draft,
  inProgress,
  completed,
  rejected,
  approved;

  static InspectionState fromString(String? state) {
    if (state == null) return InspectionState.draft;
    switch (state.toLowerCase()) {
      case 'draft':
        return InspectionState.draft;
      case 'in_progress':
      case 'inprogress':
        return InspectionState.inProgress;
      case 'completed':
      case 'done':
        return InspectionState.completed;
      case 'rejected':
      case 'cancelled':
        return InspectionState.rejected;
      case 'approved':
        return InspectionState.approved;
      default:
        return InspectionState.draft;
    }
  }

  String get displayName => switch (this) {
    InspectionState.draft => 'Draft',
    InspectionState.inProgress => 'In Progress',
    InspectionState.completed => 'Completed',
    InspectionState.rejected => 'Rejected',
    InspectionState.approved => 'Approved',
  };

  Color get color => switch (this) {
    InspectionState.draft => const Color(0xFF9E9E9E),
    InspectionState.inProgress => const Color(0xFF2196F3),
    InspectionState.completed => const Color(0xFF4CAF50),
    InspectionState.rejected => const Color(0xFFF44336),
    InspectionState.approved => const Color(0xFF00BCD4),
  };
}
