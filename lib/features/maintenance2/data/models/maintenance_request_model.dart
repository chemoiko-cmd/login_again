class MaintenanceRequestModel {
  final String title;

  MaintenanceRequestModel({required this.title});

  factory MaintenanceRequestModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceRequestModel(title: map['display_name'] ?? '');
  }
}
