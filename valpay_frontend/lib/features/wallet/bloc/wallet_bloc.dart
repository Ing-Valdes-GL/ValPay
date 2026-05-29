import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';

// Events
abstract class WalletEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {}

// States
abstract class WalletState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}
class WalletLoading extends WalletState {}
class WalletLoaded extends WalletState {
  final double balance;
  final String currency;
  final List<Map<String, dynamic>> transactions;
  final String userName;
  final String userPhone;
  WalletLoaded({
    required this.balance,
    required this.currency,
    required this.transactions,
    required this.userName,
    required this.userPhone,
  });
  @override
  List<Object?> get props => [balance, transactions, userName, userPhone];
}
class WalletError extends WalletState {
  final String message;
  WalletError({required this.message});
}

// BLoC
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final ApiClient _api = ApiClient.instance;

  WalletBloc() : super(WalletInitial()) {
    on<WalletLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(WalletLoadRequested event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      final results = await Future.wait([
        _api.dio.get('/wallet/balance'),
        _api.dio.get('/wallet/transactions'),
        _api.dio.get('/auth/me'),
      ]);

      final balanceData = results[0].data;
      final txData = results[1].data;
      final userData = results[2].data;

      emit(WalletLoaded(
        balance: double.parse(balanceData['balance'].toString()),
        currency: balanceData['currency'] ?? 'XAF',
        transactions: List<Map<String, dynamic>>.from(txData['data'] ?? []),
        userName: userData['name'] ?? '',
        userPhone: userData['phone_number'] ?? '',
      ));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }
}
