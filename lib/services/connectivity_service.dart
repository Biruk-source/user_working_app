import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();

    if (_isOnline) {
      // Sync cached data with server when back online
      await _syncCachedData();
    }
  }

  Future<void> _syncCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCachedData = prefs.getBool('has_cached_data') ?? false;
    
    if (hasCachedData) {
      // TODO: Implement data sync logic
      await prefs.setBool('has_cached_data', false);
    }
  }

  Future<bool> retryConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return _isOnline;
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
