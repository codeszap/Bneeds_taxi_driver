class VehicleSubType {
  final String vehSubTypeId;
  final String vehSubTypeName;
//  final String vehTypeId;
  final String totalKms;

  VehicleSubType({
    required this.vehSubTypeId,
    required this.vehSubTypeName,
    //required this.vehTypeId,
    required this.totalKms,
  });

  factory VehicleSubType.fromJson(Map<String, dynamic> json) {
    return VehicleSubType(
      vehSubTypeId: json['VehSubTypeid'] ?? '',
      vehSubTypeName: json['VehsubTypeName'] ?? '',
     // vehTypeId: json['VehTypeid'] ?? '',
      totalKms: json['Totalkm'] ?? '',
    );
  }
}
