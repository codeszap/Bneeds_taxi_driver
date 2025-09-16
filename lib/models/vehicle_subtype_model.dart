class VehicleSubType {
  final String vehSubTypeId;
  final String vehSubTypeName;

  VehicleSubType({
    required this.vehSubTypeId,
    required this.vehSubTypeName,
  });

  factory VehicleSubType.fromJson(Map<String, dynamic> json) {
    return VehicleSubType(
      vehSubTypeId: json['VehsubTypeid'] ?? '',   // lowercase "s"
      vehSubTypeName: json['VehsubTypeName'] ?? '', // uppercase "N"
    );
  }
}
