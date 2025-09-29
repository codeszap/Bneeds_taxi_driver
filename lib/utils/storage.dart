// lib/utils/storage.dart

// -------------------- Dart --------------------
export 'dart:async';
export 'dart:convert';
export 'dart:io';
export 'dart:math';

// -------------------- Flutter --------------------
export 'package:flutter/material.dart';
export 'package:flutter/widgets.dart';

// -------------------- Packages --------------------
export 'package:go_router/go_router.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:flutter_local_notifications/flutter_local_notifications.dart';
export 'package:image_picker/image_picker.dart';
export 'package:dio/dio.dart';
export 'package:flutter_switch/flutter_switch.dart';
export 'package:audioplayers/audioplayers.dart';
export 'package:smooth_page_indicator/smooth_page_indicator.dart';
export 'package:geolocator/geolocator.dart';
export 'package:google_maps_flutter/google_maps_flutter.dart';

// -------------------- Project Models --------------------
export 'package:bneeds_taxi_driver/models/vehicle_type_model.dart';
export 'package:bneeds_taxi_driver/models/vehicle_subtype_model.dart';
export 'package:bneeds_taxi_driver/models/user_profile_model.dart';

// -------------------- Project Providers --------------------
export 'package:bneeds_taxi_driver/providers/vehicle_type_provider.dart';
export 'package:bneeds_taxi_driver/providers/vehicle_subtype_provider.dart';
export 'package:bneeds_taxi_driver/providers/profile_provider.dart';
export 'package:bneeds_taxi_driver/providers/driverStatusProvider.dart';
export 'package:bneeds_taxi_driver/providers/booking_provider.dart';

// -------------------- Project Repositories --------------------
export 'package:bneeds_taxi_driver/repositories/profile_repository.dart';

// -------------------- Project Services --------------------
export 'package:bneeds_taxi_driver/services/FirebasePushService.dart';
export 'package:bneeds_taxi_driver/services/firebase_service.dart';

// -------------------- Project Screens --------------------
export 'package:bneeds_taxi_driver/screens/onTrip/OnTripScreen.dart';
export 'package:bneeds_taxi_driver/screens/login/login_screen.dart';
export 'package:bneeds_taxi_driver/screens/ProfileScreen.dart';
export 'package:bneeds_taxi_driver/screens/WalletScreen.dart';
export 'package:bneeds_taxi_driver/screens/TripCompleteScreen.dart';
export 'package:bneeds_taxi_driver/screens/CustomerSupportScreen.dart';
export 'package:bneeds_taxi_driver/screens/splash_screen.dart';

// -------------------- Project Widgets --------------------
export 'package:bneeds_taxi_driver/widgets/common_textfield.dart';
export 'package:bneeds_taxi_driver/widgets/common_drawer.dart';
export 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';

// -------------------- Project Config & Utilities --------------------
export 'package:bneeds_taxi_driver/config/routes.dart';
export 'package:bneeds_taxi_driver/config/RouteDecider.dart';
export 'package:bneeds_taxi_driver/utils/sharedPrefrencesHelper.dart';
export 'package:bneeds_taxi_driver/utils/constants.dart';
export 'package:bneeds_taxi_driver/core/api_client.dart';
export 'package:bneeds_taxi_driver/core/api_endpoints.dart';

export 'package:bneeds_taxi_driver/theme/app_colors.dart';