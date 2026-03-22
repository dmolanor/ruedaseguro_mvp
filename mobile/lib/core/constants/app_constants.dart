class AppConstants {
  AppConstants._();

  // OCR
  static const double ocrConfidenceThreshold = 0.9;
  static const double ocrConfidenceAmber = 0.5;

  // Image quality (anti-fraud)
  static const double sharpnessThreshold = 100.0;

  // Telemetry (Phase 1.5)
  static const double impactThreshold = 9.0; // G-force

  // File limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // OTP
  static const int otpLength = 6;
  static const int otpExpirySeconds = 300;
  static const int otpResendSeconds = 60;

  // BCV
  static const int bcvRefreshIntervalMinutes = 30;

  // Phone
  static const String venezuelaCountryCode = '+58';
}
