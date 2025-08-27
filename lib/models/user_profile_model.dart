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
    };
  }
}
