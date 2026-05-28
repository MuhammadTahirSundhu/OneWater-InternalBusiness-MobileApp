import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user_model.dart';

// Providers
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(storage);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});

// Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  SecureStorageService get _storage => _ref.read(secureStorageProvider);
  DioClient get _dio => _ref.read(dioClientProvider);

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isAuth = await _storage.isAuthenticated();
      if (isAuth) {
        final userData = await _storage.getUserData();
        if (userData != null) {
          state = AuthState(
            user: UserModel.fromJson(userData),
            isAuthenticated: true,
          );

          // Fetch fresh user data in background
          _refreshUserData();
          return;
        }
      }
      state = const AuthState(isAuthenticated: false);
    } catch (e) {
      state = const AuthState(isAuthenticated: false);
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final data = response.data;

      await _storage.setAccessToken(data['access_token']);
      await _storage.setRefreshToken(data['refresh_token']);

      final user = UserModel.fromJson(data['user']);
      await _storage.setUserData(data['user']);

      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: msg.toString());
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {}

    await _storage.clearAuth();
    state = const AuthState(isAuthenticated: false);
  }

  Future<void> _refreshUserData() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final user = UserModel.fromJson(response.data);
      await _storage.setUserData(response.data);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
