import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String password;
  AuthLoginRequested({required this.phone, required this.password});
  @override
  List<Object?> get props => [phone, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String email;
  final String password;
  AuthRegisterRequested({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });
}

class AuthLogoutRequested extends AuthEvent {}
class AuthCheckRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api = ApiClient.instance;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final hasToken = await _api.hasToken();
    if (hasToken) {
      try {
        final response = await _api.dio.get('/auth/me');
        emit(AuthAuthenticated(user: response.data));
      } catch (_) {
        await _api.clearToken();
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _api.dio.post('/auth/login', data: {
        'phone_number': event.phone,
        'password': event.password,
      });
      await _api.setToken(response.data['token']);
      emit(AuthAuthenticated(user: response.data['user']));
    } on Exception catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _api.dio.post('/auth/register', data: {
        'name': event.name,
        'phone_number': event.phone,
        'email': event.email,
        'password': event.password,
        'password_confirmation': event.password,
      });
      await _api.setToken(response.data['token']);
      emit(AuthAuthenticated(user: response.data['user']));
    } on Exception catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _api.dio.post('/auth/logout');
    } finally {
      await _api.clearToken();
      emit(AuthUnauthenticated());
    }
  }
}
