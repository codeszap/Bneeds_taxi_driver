// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class TripFirebaseService {
//   // 'trips' என்ற collection-ஐக் குறிப்பிடுகிறோம்.
//   // இந்த collection-ல் தான் ஒவ்வொரு பயணத்தின் விவரங்களையும் சேமிப்போம்.
//   final CollectionReference _tripsCollection = FirebaseFirestore.instance
//       .collection('trips');
//
//   /// Firestore-ல் பயணத்தின் தரவை உருவாக்கும் அல்லது புதுப்பிக்கும் செயல்பாடு.
//   /// [bookingId] என்பது Firestore ஆவணத்தின் தனித்துவமான ID ஆகப் பயன்படுத்தப்படும்.
//   /// [tripData] என்பது சேமிக்கப்பட வேண்டிய தரவைக் கொண்ட ஒரு Map ஆகும்.
//   Future<void> createOrUpdateTrip({
//     required String bookingId,
//     required Map<String, dynamic> tripData,
//   }) async {
//     try {
//       // .doc(bookingId) - பயணத்தின் bookingId-ஐ ஆவணத்தின் ID ஆகப் பயன்படுத்துகிறது.
//       // .set(tripData, SetOptions(merge: true)) - இந்த ID-ல் ஆவணம் ஏற்கெனவே இருந்தால்,
//       // புதிய தரவை பழைய தரவுடன் இணைக்கும். இல்லையெனில், புதிய ஆவணத்தை உருவாக்கும்.
//       await _tripsCollection
//           .doc(bookingId)
//           .set(tripData, SetOptions(merge: true));
//       print(
//         '✅ Firestore: Trip data for bookingId: $bookingId saved successfully.',
//       );
//     } catch (e) {
//       print('❌ Firestore: Error saving trip data: $e');
//       // பிழையை மீண்டும் அனுப்புவதன் மூலம், அழைக்கும் இடத்தில் இதைக் கையாளலாம்.
//       rethrow;
//     }
//   }
//
//   /// ஒரு குறிப்பிட்ட பயணத்தின் தரவைப் பெறும் செயல்பாடு (இது பின்னர் OTP சரிபார்ப்புக்குத் தேவைப்படும்).
//   Future<DocumentSnapshot?> getTripDetails(String bookingId) async {
//     try {
//       return await _tripsCollection.doc(bookingId).get();
//     } catch (e) {
//       print('❌ Firestore: Error fetching trip data: $e');
//       return null;
//     }
//   }
// }
