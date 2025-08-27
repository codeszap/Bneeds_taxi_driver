class VehicleTypeModel {
  final String vehTypeid;
  final String vehTypeName;

  VehicleTypeModel({
    required this.vehTypeid,
    required this.vehTypeName,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      vehTypeid: json['VehTypeid'] ?? '',
      vehTypeName: json['VehTypeName'] ?? '',
    );
  }
}
