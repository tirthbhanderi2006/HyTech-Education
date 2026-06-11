import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/user_model.dart';
import '../../../core/storage/token_storage.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email, password;
  const AuthLoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email, password, fullName;
  final String? phone, nationality;
  const AuthRegisterRequested({
    required this.email, required this.password, required this.fullName,
    this.phone, this.nationality,
  });
  @override List<Object?> get props => [email, fullName];
}

class AuthProfileUpdateRequested extends AuthEvent {
  final Map<String, dynamic> updates;
  const AuthProfileUpdateRequested(this.updates);
  @override List<Object?> get props => [updates];
}

class AuthCheckRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}

// ── States ────────────────────────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthInitial      extends AuthState {}
class AuthLoading      extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApi _api = AuthApi();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthProfileUpdateRequested>(_onProfileUpdate);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final loggedIn = await TokenStorage.isLoggedIn();
    if (!loggedIn) { emit(AuthUnauthenticated()); return; }
    try {
      final user = await _api.getMe();
      emit(AuthAuthenticated(user));
    } catch (_) {
      await TokenStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _api.login(email: e.email, password: e.password);
      emit(AuthAuthenticated(user));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Login failed. Please try again.'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _api.register(
        email: e.email, password: e.password, fullName: e.fullName,
        phone: e.phone, nationality: e.nationality,
      );
      emit(AuthAuthenticated(user));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onProfileUpdate(AuthProfileUpdateRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _api.updateProfile(e.updates);
      emit(AuthAuthenticated(user));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _api.logout();
    emit(AuthUnauthenticated());
  }
}
