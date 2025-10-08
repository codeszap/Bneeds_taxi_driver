class CancelModel {
  final String Bookingid;
  final String decline_reason;

  CancelModel({
    required this.Bookingid,
    required this.decline_reason,
  });

  Map<String, dynamic> toMap() {
    return {
      "Bookingid": Bookingid,
      "decline_reason": decline_reason,
    };
  }
}
