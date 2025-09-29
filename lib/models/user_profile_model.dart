class DriverProfile {
  final String riderId;
  final String riderName;
  final String userName;
  final String password;
  final String mobileNo;
  final String vehTypeId;
  final String vehSubTypeId;
  final String Vehtypename;
  final String VehsubTypename;
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
    required this.Vehtypename,
    required this.vehSubTypeId,
    required this.VehsubTypename,
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
      vehTypeId: json['Vehtypeid'] ?? '1',
      Vehtypename: json['Vehtypename'] ?? '',
      vehSubTypeId: json['VehsubTypeid'] ?? '1',
      VehsubTypename: json['VehsubTypename'] ?? '',
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
      "Riderid" : riderId,
      "RiderName": riderName,
      "userName": userName,
      "password": password,
      "MobileNo": mobileNo,
      "Vehtypeid": vehTypeId,
      "Vehtypename": Vehtypename,
      "VehsubTypeid": vehSubTypeId,
      "VehsubTypename": VehsubTypename,
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

class UserProfile {
  final String userid;
  final String userName;
  final String mobileNo;
  final String password;
  final String gender;
  final String dob;
  final String address1;
  final String address2;
  final String address3;
  final String city;
  final String tokenkey;

  UserProfile({
    required this.userid,
    required this.userName,
    required this.mobileNo,
    required this.password,
    required this.gender,
    required this.dob,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.city,
    required this.tokenkey,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userid: json['userid'] ?? '',
      userName: json['userName'] ?? '',
      mobileNo: json['mobileno'] ?? '',
      password: json['Password'] ?? '',
      gender: json['Gender'] ?? '',
      dob: json['dob'] ?? '',
      address1: json['Address1'] ?? '',
      address2: json['Address2'] ?? '',
      address3: json['Address3'] ?? '',
      city: json['City'] ?? '',
      tokenkey: json['tokenkey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userid": userid,
      "userName": userName,
      "mobileno": mobileNo,
      "password": password,
      "gender": gender,
      "dob": dob,
      "address1": address1,
      "address2": address2,
      "address3": address3,
      "city": city,
      "tokenkey": tokenkey,
    };
  }
}

