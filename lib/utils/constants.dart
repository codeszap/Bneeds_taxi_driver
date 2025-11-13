class Strings {
  static const String appTitle = 'Ram Meter Driver';
  // -------------------- API Keys --------------------
  static const String googleApiKey = "AIzaSyAWzUqf3Z8xvkjYV7F4gOGBBJ5d_i9HZhs";

  // -------------------- Assets --------------------
  static const String logo = 'assets/images/logo.png';
  static const String rideRequestSound = 'sounds/ride_request.mp3';
  static const String onOffSound = 'sounds/on-off.mp3';
  static const String serviceAccount = 'assets/service-account.json';

  // -------------------- Trip / Booking --------------------
  static const String tripCompleted = "Trip Completed 🎉";
  static const String farePrefix = "Fare: ₹";
  static const String paymentCash = "Payment: Cash";
  static const String readyForNextRide = "Ready for Next Ride";
  static const String submitFare = "Submit Fare";
  static const String bookingFailed = "❌ Failed to complete booking";

  // -------------------- Push Notifications --------------------
  static const String rideCompleted = "Ride Completed ✅";
  static const String rideCompletedBody = "Your trip has been completed. Fare: ₹";
  static const String rideStarted = "Ride Started✅";
  static const String rideStartedBody = "Your ride has started. Sit back and relax!";
  static const String statusStartTrip = "start trip";
  static const String driverArrived = "Driver Arrived at Pickup ✅";
  static const String driverArrivedBody = "Your driver has arrived at the pickup location.";
  static const String statusArrivedPickup = "arrived_pickup";

  // -------------------- OTP / Dialog --------------------
  static const String enterOtp = "Enter OTP";
  static const String enterOtpDesc = "Enter the 4-digit OTP sent to the user.";
  static const String invalidOtp = "Invalid OTP";
  static const String cancel = "Cancel";

  // -------------------- Permissions / Errors --------------------
  static const String locationDenied = "Location permission permanently denied. Please enable it in settings.";
  static const String errorGettingPosition = "Error getting current position:";
  static const String errorGettingDirections = "Error getting directions:";

  // -------------------- UI Labels --------------------
  static const String tripInfo = "Trip Info";
  static const String pickupLabel = "📍 Pickup: ";
  static const String dropLabel = "🏁 Drop: ";
  static const String fareLabel = "💰 Fare: ₹";
  static const String elapsedTime = "⏱️ Elapsed Time: ";
  static const String customerInfo = "Customer Info";
  static const String nameLabel = "👤 Name: ";
  static const String mobileLabel = "📞 Mobile: ";
  static const String addressLabel = "🏠 Address: ";
  static const String otpLabel = "OTP: ";
  static const String startTrip = "Start Trip";
  static const String pickupButton = "Pickup";
  static const String dropButton = "Drop";
}
