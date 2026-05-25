class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator → localhost
  );

  static const String appName = 'ValPay';
  static const String currency = 'XAF';
  static const String currencySymbol = 'FCFA';

  // Frais
  static const double transferFeeRate = 0.01; // 1%
  static const double withdrawFeeRate = 0.01;
  static const double depositFeeRate = 0.0;

  // Limites
  static const double minTransactionAmount = 100;
  static const double maxTransactionAmount = 1000000;
  static const double minDepositAmount = 500;
  static const double minWithdrawalAmount = 500;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Cameroun
  static const String phonePrefix = '+237';
  static const String phonePlaceholder = '+237 6XX XXX XXX';
}
