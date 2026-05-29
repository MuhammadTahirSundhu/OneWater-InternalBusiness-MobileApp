import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stream provider for real-time connectivity
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Simple bool provider — true when online
final isOnlineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityStreamProvider);
  return result.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    loading: () => true,  // Assume online while loading
    error: (error, stackTrace) => true,
  );
});

