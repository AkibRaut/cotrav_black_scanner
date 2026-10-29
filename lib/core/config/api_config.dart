/// Endpoints for the Cotrav events API.
abstract final class ApiConfig {
  static const baseUrl = 'https://demo.taxivaxi.com/mapi/v3';

  static String get passwordLogin => '$baseUrl/events/login';
  static String get sendOtp => '$baseUrl/events/sendOtpForLogin';
  static String get verifyOtp => '$baseUrl/events/validateOtp';
  static String get forgotPassword => '$baseUrl/events/forgotPassword';
  static String get resetPassword => '$baseUrl/events/resetPassword';
}
