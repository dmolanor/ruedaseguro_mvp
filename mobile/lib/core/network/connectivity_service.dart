import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Timer? _debounce;

  Stream<bool> get onStatusChange => _controller.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen(_handleChange);
  }

  void _handleChange(List<ConnectivityResult> results) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final connected = await isConnected;
      _controller.add(connected);
    });
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;
    // Verify actual internet access
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}
