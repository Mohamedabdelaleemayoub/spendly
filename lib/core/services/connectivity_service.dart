import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get isOnlineStream;
  Future<bool> checkConnectivity();
  void dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get isOnlineStream => _controller.stream;

  void _init() {
    // Initial check
    checkConnectivity();

    // Listen to changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityResults(results);
    });
  }

  Future<void> _handleConnectivityResults(List<ConnectivityResult> results) async {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) {
      _updateStatus(false);
      return;
    }

    // Verify real internet reachability
    final reachable = await _verifyInternetReachability();
    _updateStatus(reachable);
  }

  Future<bool> _verifyInternetReachability() async {
    if (kIsWeb) return true;
    try {
      final lookup = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final lookupBackup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return lookupBackup.isNotEmpty && lookupBackup[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        _updateStatus(false);
        return false;
      }
      final reachable = await _verifyInternetReachability();
      _updateStatus(reachable);
      return reachable;
    } catch (e) {
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      _controller.add(status);
      debugPrint('🌐 [ConnectivityService] Network status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
