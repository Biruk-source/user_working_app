import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rive/rive.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive/rive.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_animate/flutter_animate.dart';


class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestLocationPermissions() async {
    // Request location permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
    ].request();

    // Check if all location permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    // If not all permissions are granted, but some are, request background location
    if (!allGranted && statuses[Permission.locationWhenInUse]?.isGranted == true) {
      final backgroundStatus = await Permission.backgroundLocation.request();
      allGranted = backgroundStatus.isGranted;
    }

    return allGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestBatteryOptimizationPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<bool> requestAllRequiredPermissions() async {
    bool locationGranted = await requestLocationPermissions();
    bool notificationGranted = await requestNotificationPermission();
    bool batteryOptGranted = await requestBatteryOptimizationPermission();

    return locationGranted && notificationGranted && batteryOptGranted;
  }

  Future<bool> checkLocationPermissions() async {
    bool locationWhenInUse = await Permission.locationWhenInUse.isGranted;
    bool locationAlways = await Permission.locationAlways.isGranted;
    bool backgroundLocation = await Permission.backgroundLocation.isGranted;

    return locationWhenInUse && locationAlways && backgroundLocation;
  }
}
