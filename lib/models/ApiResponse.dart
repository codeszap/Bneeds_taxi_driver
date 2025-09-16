class ApiResponse {
  final String status;
  final String message;

  ApiResponse({required this.status, required this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json["status"],
      message: json["message"],
    );
  }
}
