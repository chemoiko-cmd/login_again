class LandlordMetricsModel {
  final int totalUnits;
  final int occupiedUnits;
  final double occupancyRate;
  final int totalRentCollected;
  final int totalRentDue;
  final int outstanding; // <-- added
  final int openMaintenanceTasks;
  final int pendingApprovals;

  LandlordMetricsModel({
    required this.totalUnits,
    required this.occupiedUnits,
    required this.occupancyRate,
    required this.totalRentCollected,
    required this.totalRentDue,
    required this.outstanding, // <-- added
    required this.openMaintenanceTasks,
    required this.pendingApprovals,
  });

  factory LandlordMetricsModel.fromMap(Map<String, dynamic> map) {
    return LandlordMetricsModel(
      totalUnits: map['totalUnits'] ?? 0,
      occupiedUnits: map['occupiedUnits'] ?? 0,
      occupancyRate: (map['occupancyRate'] ?? 0).toDouble(),
      totalRentCollected: (map['totalRentCollected'] ?? 0) as int,
      totalRentDue: (map['totalRentDue'] ?? 0) as int,
      outstanding: (map['outstanding'] ?? 0) as int, // <-- added
      openMaintenanceTasks: map['openMaintenanceTasks'] ?? 0,
      pendingApprovals: map['pendingApprovals'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'LandlordMetrics(totalUnits: $totalUnits, occupiedUnits: $occupiedUnits, occupancyRate: $occupancyRate, collected: $totalRentCollected, due: $totalRentDue, outstanding: $outstanding, maintenance: $openMaintenanceTasks, pending: $pendingApprovals)';
  }
}
