class DriverProfile {
  final String riderId;
  final String riderName;
  final String userName;
  final String password;
  final String mobileNo;
  final String vehTypeId;
  final String vehSubTypeId;
  final String vehNo;
  final String fcDate;
  final String insDate;
  final String tokenKey;
  final String gender;
  final String dateOfBirth;
  final String add1;
  final String add2;
  final String add3;
  final String city;
  final String licenseNo;
  final String adhaarNo;

  DriverProfile({
    required this.riderId,
    required this.riderName,
    required this.userName,
    required this.password,
    required this.mobileNo,
    required this.vehTypeId,
    required this.vehSubTypeId,
    required this.vehNo,
    required this.fcDate,
    required this.insDate,
    required this.tokenKey,
    required this.gender,
    required this.dateOfBirth,
    required this.add1,
    required this.add2,
    required this.add3,
    required this.city,
    required this.licenseNo,
    required this.adhaarNo,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      riderId: json['Riderid'] ?? '',
      riderName: json['RiderName'] ?? '',
      userName: json['userName'] ?? '',
      password: json['password'] ?? '',
      mobileNo: json['MobileNo'] ?? '',
      vehTypeId: json['Vehtypeid'] ?? '',
      vehSubTypeId: json['VehsubTypeid'] ?? '',
      vehNo: json['VehNo'] ?? '',
      fcDate: json['FCDate'] ?? '',
      insDate: json['InsDate'] ?? '',
      tokenKey: json['tokenkey'] ?? '',
      gender: json['Gender'] ?? '',
      dateOfBirth: json['dateofbirth'] ?? '',
      add1: json['add1'] ?? '',
      add2: json['add2'] ?? '',
      add3: json['add3'] ?? '',
      city: json['city'] ?? '',
      licenseNo: json['licenseNo'] ?? '',
      adhaarNo: json['adhaarno'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "RiderName": riderName,
      "userName": userName,
      "password": password,
      "MobileNo": mobileNo,
      "Vehtypeid": vehTypeId,
      "VehsubTypeid": vehSubTypeId,
      "VehNo": vehNo,
      "FCDate": fcDate,
      "InsDate": insDate,
      "tokenkey": tokenKey,
      "Gender": gender,
      "dateofbirth": dateOfBirth,
      "add1": add1,
      "add2": add2,
      "add3": add3,
      "city": city,
      "licenseNo": licenseNo,
      "adhaarno": adhaarNo,
    };
  }
}
